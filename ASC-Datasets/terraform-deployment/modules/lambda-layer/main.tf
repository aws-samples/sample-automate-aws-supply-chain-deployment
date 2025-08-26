resource "null_resource" "lambda_layer" {
  count = var.create_layer_file ? 1 : 0

  triggers = var.create_layer_file ? {
    source_code_hash = timestamp()        //Run this everytime to trigger updates to S3 object and layer versions
  } : {
    dummy = "no-op"
  }
  provisioner "local-exec" {
    interpreter = ["/bin/bash", "-c"]
    command = <<EOT
        echo "creating layers with packages..."

        cd "${path.root}"
        cur_path="${path.cwd}"
        mkdir -p "$cur_path/${var.layer_temp_dir}"
        mkdir -p "/tmp/${var.layer_name}"

        # Copy the layer files directory to a temporary folder
        cp -R "${path.cwd}/${trimspace(trimsuffix(var.source_path_lambda_layer, "/"))}"/* "/tmp/${var.layer_name}/"

        if ${var.install_libraries}; then
            echo "Installing dependencies from ${var.installation_file_name}..."
            
            # Check if it's a Node.js library file (package.json)
            if [[ "${var.installation_file_name}" == "package.json" ]]; then
                echo "Installing Node.js dependencies..."
                
                mkdir -p "/tmp/${var.layer_name}/nodejs"
                mv "/tmp/${var.layer_name}/package.json" "/tmp/${var.layer_name}/nodejs/"
                
                # Install the node packages
                cd "/tmp/${var.layer_name}/nodejs/"
                npm install > /dev/null
                rm -rf package.json
                rm -rf package-lock.json

            # Check if it's a Python library file (requirements.txt)
            elif [[ "${var.installation_file_name}" == "requirements.txt" ]]; then
                echo "Installing Python dependencies..."
                
                mkdir -p "/tmp/${var.layer_name}/python"
                mv "/tmp/${var.layer_name}/requirements.txt" "/tmp/${var.layer_name}/python/"

                # Create and activate virtual environment
                # echo "Python version: $(python --version)"
                ${var.runtime} -m venv "/tmp/${var.layer_name}/env_python"
                source "/tmp/${var.layer_name}/env_python/bin/activate"

                # Install Python packages
                pip install --upgrade -r "/tmp/${var.layer_name}/python/requirements.txt" --platform manylinux2014_x86_64 --only-binary=:all: -t "/tmp/${var.layer_name}/python/" > /dev/null

                # Deactivate virtual environment
                deactivate
                rm -rf "/tmp/${var.layer_name}/env_python"
                rm -f "/tmp/${var.layer_name}/python/requirements.txt"
            else
                echo "Unsupported library file format"
                exit 1
            fi
        else
              echo "Keeping files as it is in the Zip"
        fi

        # Remove existing zip file if it exists
        rm -f "$cur_path/${var.layer_temp_dir}/${var.output_path_layer_file}"

        # Zip the installed directory
        cd "/tmp/${var.layer_name}/"
        zip -FSr "$cur_path/${var.layer_temp_dir}/${var.output_path_layer_file}" ./* > /dev/null

        # Cleaning up
        rm -rf "/tmp/${var.layer_name}"
    EOT
  }
}

resource "aws_s3_object" "this" {
  depends_on = [ null_resource.lambda_layer[0] ]

  bucket                  = var.s3_bucket
  key                     = var.layer_key
  source                  = var.create_layer_file ? "${path.root}/${var.layer_temp_dir}/${var.output_path_layer_file}" : try("${path.root}/${var.zipped_layer_file}", null)
  server_side_encryption  = var.s3_encryption
  kms_key_id              = var.s3_encryption == "aws:kms" ? var.kms_key_arn_s3 : null
  source_hash             = filemd5(var.create_layer_file ? "${path.root}/${var.layer_temp_dir}/hash/${var.output_path_layer_file}" : try("${path.root}/${var.zipped_layer_file}", null))

  tags                    = var.tags
}

resource "aws_lambda_layer_version" "this" {
  depends_on  = [ aws_s3_object.this ]

  layer_name            = var.layer_name
  s3_bucket             = var.s3_bucket
  s3_key                = var.layer_key
  compatible_runtimes   = ["${var.runtime}"]
  source_code_hash      = filebase64sha256(var.create_layer_file ? "${path.root}/${var.layer_temp_dir}/hash/${var.output_path_layer_file}" : try("${path.root}/${var.zipped_layer_file}", null))
}