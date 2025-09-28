# Software (software, scripts or sample code) is licensed under the Apache License, Version 2.0.
# Author: AWS Professional Services

module "asc_layer_boto3" {
  source = "./modules/lambda-layer"

  create_layer_file         = true
  layer_name                = "${var.project_name}-${var.environment}-asc-boto3-public"
  runtime                   = "python3.13"
  
  install_libraries         = true
  installation_file_name    = "requirements.txt"

  s3_bucket                 = module.s3_buckets["artifacts"].bucket_name
  s3_encryption             = "aws:kms"
  kms_key_arn_s3            = module.kms_keys["artifacts"].arn
  layer_key                 = "lambda_layers/asc/asc-boto3-public.zip"
  source_path_lambda_layer  = "../dependencies/asc-boto3-layer/"
  output_path_layer_file    = "asc-boto3-public.zip"
  layer_temp_dir            = var.layer_temp_dir
}