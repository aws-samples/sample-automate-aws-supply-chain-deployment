# Software (software, scripts or sample code) is licensed under the Apache License, Version 2.0.
# Author: AWS Professional Services

resource "aws_iam_policy" "this" {
  for_each    = var.policy_configs
  name_prefix = each.value.policy_name_prefix
  path        = lookup(each.value, "path", "/")
  description = lookup(each.value, "description", null)
  policy      = lookup(each.value, "policy_statement", null)
  tags        = lookup(each.value, "tags", {})
}

resource "aws_iam_policy" "iam_pass_role" {
  count       = var.create_pass_role_policy ? 1 : 0
  name_prefix = local.iam_access_config.policy_name_prefix
  path        = lookup(local.iam_access_config, "path", "/")
  description = lookup(local.iam_access_config, "description", null)
  policy      = lookup(local.iam_access_config, "policy_statement", null)
  tags        = lookup(local.iam_access_config, "tags", {})
}

resource "aws_iam_role_policy_attachment" "this" {
  count      = local.role_name != null ? length(local.policy_arns) : 0
  depends_on = [aws_iam_policy.this, aws_iam_policy.iam_pass_role]
  role       = local.role_name
  policy_arn = local.policy_arns[count.index]
}