# Software (software, scripts or sample code) is licensed under the Apache License, Version 2.0.
# Author: AWS Professional Services

module "asc_lambda_execution_role" {
  source = "./modules/iam"

  role_name           = "${var.project_name}-${var.environment}-asc-lambda-role-${local.account_id}"
  trust_policy        = data.aws_iam_policy_document.lambda_trust_policy_document.json
  description         = "IAM Policy used by ASC Dataset lambda"
  policy_configs      = local.lambda_asc_policy_configs
  managed_policy_arns = ["arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole", "arn:aws:iam::aws:policy/service-role/AWSLambdaVPCAccessExecutionRole"]

  tags                = var.tags
}

module "asc_instance_lambda" {
  source = "./modules/lambda"

  function_name           = "${var.project_name}-${var.environment}-asc-instance-lambda"
  description             = "Lambda code to create/delete ASC instance"
  handler                 = "function_code.lambda_handler"
  runtime                 = "python3.13"
  timeout                 = "300"
  memory_size             = "256"
  lambda_role_arn         = module.asc_lambda_execution_role.role_arn

  inside_vpc              = true
  vpc_id                  = var.vpc_config[0].vpc_id
  vpc_subnet_ids          = var.vpc_config[0].subnets
  security_group_id       = module.lambda_sg.sg_id
  replace_sg_on_destroy   = true

  layer_arns              = [module.asc_layer_boto3.layer_arn]

  s3_bucket               = module.s3_buckets["artifacts"].bucket_name
  s3_encryption           = "aws:kms"
  kms_key_arn_s3          = module.kms_keys["artifacts"].arn
  s3_key_lambda           = "lambda_artifacts/asc/asc-instance.zip"
  source_path_lambda      = "../lambda-code/asc_instance/"
  output_path_lambda_file = "asc-instance.zip"
  lambda_temp_dir         = "${var.lambda_temp_dir}"

  tags = var.tags
}

module "asc_namespace_lambda" {
  source = "./modules/lambda"

  function_name           = "${var.project_name}-${var.environment}-asc-namespace-lambda"
  description             = "Lambda code to create/delete ASC namespace"
  handler                 = "function_code.lambda_handler"
  runtime                 = "python3.13"
  timeout                 = "300"
  memory_size             = "256"
  lambda_role_arn         = module.asc_lambda_execution_role.role_arn

  inside_vpc              = true
  vpc_id                  = var.vpc_config[0].vpc_id
  vpc_subnet_ids          = var.vpc_config[0].subnets
  security_group_id       = module.lambda_sg.sg_id
  replace_sg_on_destroy   = true

  layer_arns              = [module.asc_layer_boto3.layer_arn]

  s3_bucket               = module.s3_buckets["artifacts"].bucket_name
  s3_encryption           = "aws:kms"
  kms_key_arn_s3          = module.kms_keys["artifacts"].arn
  s3_key_lambda           = "lambda_artifacts/asc/asc-namespace.zip"
  source_path_lambda      = "../lambda-code/asc_namespace/"
  output_path_lambda_file = "asc-namespace.zip"
  lambda_temp_dir         = "${var.lambda_temp_dir}"

  tags = var.tags
}

resource "aws_cloudwatch_log_group" "asc_namespace_lambda_log_group" {
  name              = "/aws/lambda/${module.asc_namespace_lambda.function_name}"
  retention_in_days = 400
  kms_key_id        = module.kms_keys["artifacts"].arn

  tags = var.tags
}

module "asc_dataset_lambda" {
  source = "./modules/lambda"

  function_name           = "${var.project_name}-${var.environment}-asc-dataset-lambda"
  description             = "Lambda code to create/delete ASC dataset"
  handler                 = "function_code.lambda_handler"
  runtime                 = "python3.13"
  timeout                 = "300"
  memory_size             = "256"
  lambda_role_arn         = module.asc_lambda_execution_role.role_arn

  inside_vpc              = true
  vpc_id                  = var.vpc_config[0].vpc_id
  vpc_subnet_ids          = var.vpc_config[0].subnets
  security_group_id       = module.lambda_sg.sg_id
  replace_sg_on_destroy   = true

  layer_arns              = [module.asc_layer_boto3.layer_arn]

  s3_bucket               = module.s3_buckets["artifacts"].bucket_name
  s3_encryption           = "aws:kms"
  kms_key_arn_s3          = module.kms_keys["artifacts"].arn
  s3_key_lambda           = "lambda_artifacts/asc/asc-dataset.zip"
  source_path_lambda      = "../lambda-code/asc_dataset/"
  output_path_lambda_file = "asc-dataset.zip"
  lambda_temp_dir         = "${var.lambda_temp_dir}"

  tags = var.tags
}

resource "aws_cloudwatch_log_group" "asc_dataset_lambda_log_group" {
  name              = "/aws/lambda/${module.asc_dataset_lambda.function_name}"
  retention_in_days = 400
  kms_key_id        = module.kms_keys["artifacts"].arn

  tags = var.tags
}

resource "aws_lambda_invocation" "create_instance" {
  depends_on = [ module.asc_instance_lambda ]
  count      = var.instance_operation == "CREATE" ? 1 : 0

  function_name = module.asc_instance_lambda.function_name
  input         = jsonencode({
    instanceName        = local.asc_instance_name
    instanceDescription = "ASC instance for ${var.environment} environment"
    kmsKeyArn           = module.kms_keys["asc_staging"].arn
    tags                = var.tags
    function_hash       = module.asc_instance_lambda.function_hash
  })
  lifecycle_scope = "CRUD"
}

resource "aws_lambda_invocation" "create_namespace" {
  depends_on = [ 
    module.asc_namespace_lambda, 
    aws_lambda_invocation.create_instance, 
    aws_cloudwatch_log_group.asc_namespace_lambda_log_group,
    null_resource.validate_configs
  ]
  for_each = { for k,v in local.asc_unique_namespace_configs : k => v }

  function_name = module.asc_namespace_lambda.function_name
  input         = jsonencode(merge(
                    try(each.value, {}),
                    {
                      function_hash = module.asc_namespace_lambda.function_hash
                    }
                  ))
  lifecycle_scope = "CRUD"
}

resource "aws_lambda_invocation" "create_dataset" {
  depends_on = [ 
    module.asc_dataset_lambda, 
    aws_lambda_invocation.create_namespace, 
    aws_cloudwatch_log_group.asc_dataset_lambda_log_group,
    null_resource.validate_configs
  ]
  for_each   = { for k, v in local.asc_datasets_config : k => v }

  function_name = module.asc_dataset_lambda.function_name
  input         = jsonencode(merge(
                    try(each.value.input, {}),
                    {
                      function_hash = module.asc_dataset_lambda.function_hash
                    }
                  ))
  lifecycle_scope = "CRUD"
}