# Software (software, scripts or sample code) is licensed under the Apache License, Version 2.0.
# Author: AWS Professional Services

resource "aws_lambda_function" "this" {
  depends_on                         = [aws_s3_object.lambda_package]

  function_name                      = var.function_name
  description                        = var.description
  role                               = var.lambda_role_arn
  handler                            = var.handler
  memory_size                        = var.memory_size
  runtime                            = var.runtime
  timeout                            = var.timeout
  dynamic "vpc_config" {
    for_each = var.inside_vpc ? [1] : []
    content {
      security_group_ids = [var.security_group_id]
      subnet_ids         = var.vpc_subnet_ids
    }
  }
  replace_security_groups_on_destroy = var.inside_vpc ? var.replace_sg_on_destroy : null

  dynamic "environment" {
    for_each = length(var.env_var) > 0 ? [1] : []
    content {
      variables = var.env_var
    }
  }
  kms_key_arn = length(var.env_var) > 0 ? var.kms_key_arn_lambda : null

  layers                             = var.layer_arns

  s3_bucket                          = var.s3_bucket
  s3_key                             = var.s3_key_lambda
  source_code_hash                   = data.archive_file.lambda_zip.output_base64sha256

  tags                              = var.tags
}

resource "aws_lambda_permission" "lambda_trigger" {
  for_each = { for k, v in var.allowed_triggers : k => v if var.create_trigger }

  function_name          = aws_lambda_function.this.function_name

  statement_id_prefix    = try(each.value.statement_id, each.key)
  action                 = try(each.value.action, "lambda:InvokeFunction")
  principal              = try(each.value.principal, format("%s.amazonaws.com", try(each.value.service, "")))
  principal_org_id       = try(each.value.principal_org_id, null)
  source_arn             = try(each.value.source_arn, null)
  source_account         = try(each.value.source_account, null)
  event_source_token     = try(each.value.event_source_token, null)
  function_url_auth_type = try(each.value.function_url_auth_type, null)

  lifecycle {
    create_before_destroy = true
  }
}

resource "null_resource" "lambda_jar" {
  count = var.is_java ? 1 : 0

  triggers = {
    source_code_hash = data.archive_file.lambda_zip.output_base64sha256
    always_run = timestamp() //For dev purposes
  }

  provisioner "local-exec" {
    command = <<EOT
        echo "creating lambda JAR file"

        cd ${path.root}
        cur_path=${path.cwd}
        mkdir -p ${var.lambda_temp_dir}

        # creating Maven JAR file with dependencies
        cd ${var.source_path_lambda}
        echo "Running mvn clean package..."
        mvn clean package

        # Copy the JAR file to the Lambda output directory
        echo "Copying JAR to Lambda output directory..."
        output_file_name="${replace(var.output_path_lambda_file, ".zip", ".jar")}"
        output_file_path="$cur_path/${var.lambda_temp_dir}/$output_file_name"
        cp target/${var.jar_name} "$output_file_path"

        echo "JAR file copied to output directory"
        
    EOT
  }
}

resource "aws_s3_object" "lambda_package" {
  depends_on = [null_resource.lambda_jar[0]]

  bucket                  = var.s3_bucket
  key                     = var.s3_key_lambda
  source                  = var.is_java ? "${path.root}/${var.lambda_temp_dir}/${replace(var.output_path_lambda_file, ".zip", ".jar")}" : data.archive_file.lambda_zip.output_path
  server_side_encryption  = var.s3_encryption
  kms_key_id              = var.s3_encryption == "aws:kms" ? var.kms_key_arn_s3 : null
  source_hash             = filemd5(data.archive_file.lambda_zip.output_path)
  
  tags                    = var.tags
}