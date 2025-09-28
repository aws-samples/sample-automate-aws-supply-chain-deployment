# Software (software, scripts or sample code) is licensed under the Apache License, Version 2.0.
# Author: AWS Professional Services

locals {
  role_name   = var.create_role ? aws_iam_role.this[0].name : try(data.aws_iam_role.this[0].name, null)

  created_policy_arns = flatten([for key in keys(var.policy_configs) : aws_iam_policy.this[key].arn])
  pass_role_policy_arn = var.create_pass_role_policy ? [aws_iam_policy.iam_pass_role[0].arn] : []
  
  policy_arns = concat(local.created_policy_arns, local.pass_role_policy_arn, var.managed_policy_arns)

  iam_access_config = {
    policy_name_prefix      = var.pass_role_policy_name
    description             = "IAM policy to allow pass role operations"
    policy_statement        = data.aws_iam_policy_document.iam_pass_role_policy_document.json
  }
}