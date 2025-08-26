# Software (software, scripts or sample code) is licensed under the Apache License, Version 2.0.
# Author: AWS Professional Services

locals {
  aws_partition = data.aws_partition.current.partition
  account_id    = data.aws_caller_identity.current.account_id
  region        = data.aws_region.current.name

  lambda_integration_flows_policy_configs = {
    asc_access_config = {
      policy_name_prefix      = "${var.project_name}-${var.environment}-iam-policy-lambda-asc-${data.aws_region.current.name}"
      description             = "IAM policy to allow lambda function to perform asc operations"
      policy_statement        = data.aws_iam_policy_document.asc_policy_document.json
    }
  }
}