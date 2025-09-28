# Software (software, scripts or sample code) is licensed under the Apache License, Version 2.0.
# Author: AWS Professional Services

module "integration_flows_lambda_execution_role" {
  source = "./modules/iam"

  role_name           = "${var.project_name}-${var.environment}-integration-flows-lambda-role-${local.account_id}"
  trust_policy        = data.aws_iam_policy_document.lambda_trust_policy_document.json
  description         = "IAM Policy used by ASC Integration flows lambda"
  policy_configs      = local.lambda_integration_flows_policy_configs
  managed_policy_arns = ["arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole", "arn:aws:iam::aws:policy/service-role/AWSLambdaVPCAccessExecutionRole"]

  tags                = var.tags
}

module "integration_flows_lambda" {
  source = "./modules/lambda"

  function_name           = "${var.project_name}-${var.environment}-integration-flows-lambda"
  description             = "Lambda code to create/delete ASC integration flows"
  handler                 = "function_code.lambda_handler"
  runtime                 = "python3.13"
  timeout                 = "300"
  memory_size             = "256"
  lambda_role_arn         = module.integration_flows_lambda_execution_role.role_arn

  inside_vpc              = true
  vpc_id                  = var.vpc_config[0].vpc_id
  vpc_subnet_ids          = var.vpc_config[0].subnets
  security_group_id       = var.lambda_sg
  replace_sg_on_destroy   = true

  layer_arns              = [var.asc_boto3_layer_arn]

  s3_bucket               = var.s3_buckets["artifacts"]
  s3_encryption           = "aws:kms"
  kms_key_arn_s3          = "arn:aws:kms:${local.region}:${local.account_id}:key/${var.kms_keys["artifacts"]}"
  s3_key_lambda           = "lambda_artifacts/asc/asc-integration-flows.zip"
  source_path_lambda      = "../lambda-code/asc_integration_flows/"
  output_path_lambda_file = "asc-integration-flows.zip"
  lambda_temp_dir         = "${var.lambda_temp_dir}"

  tags = var.tags
}

resource "aws_cloudwatch_log_group" "integration_flows_lambda_log_group" {
  name              = "/aws/lambda/${module.integration_flows_lambda.function_name}"
  retention_in_days = 400
  kms_key_id        = "arn:aws:kms:${local.region}:${local.account_id}:key/${var.kms_keys["artifacts"]}"

  tags = var.tags
}

resource "aws_lambda_invocation" "create_flow" {
  depends_on = [ 
    module.integration_flows_lambda, 
    aws_cloudwatch_log_group.integration_flows_lambda_log_group,
    null_resource.validate_configs
  ]
  for_each   = { for k, v in local.integration_flows_config : k => v }

  function_name = module.integration_flows_lambda.function_name
  input         = jsonencode(merge(
                    try(each.value.input, {}),
                    {
                      run_id = timestamp(),
                      function_hash = module.integration_flows_lambda.function_hash
                    }
                  ))
  lifecycle_scope = "CRUD"
}