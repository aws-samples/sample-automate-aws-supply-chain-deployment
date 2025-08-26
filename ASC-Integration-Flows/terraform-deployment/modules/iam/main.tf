# Software (software, scripts or sample code) is licensed under the Apache License, Version 2.0.
# Author: AWS Professional Services

resource "aws_iam_role" "this" {
  count                 = var.create_role ? 1 : 0
  description           = var.description
  max_session_duration  = var.max_session_duration
  name                  = var.name_prefix == null ? var.role_name : null
  name_prefix           = var.role_name == null ? var.name_prefix : null
  force_detach_policies = var.force_detach_policies
  path                  = var.role_path
  assume_role_policy    = var.trust_policy
  tags                  = var.tags
  dynamic "inline_policy" {
    for_each = var.inline_policy
    content {
      name   = inline_policy.value.name
      policy = inline_policy.value.policy
    }
  }
  permissions_boundary = var.permissions_boundary_arn
}