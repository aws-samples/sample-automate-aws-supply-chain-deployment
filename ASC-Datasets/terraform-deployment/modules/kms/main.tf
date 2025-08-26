# Software (software, scripts or sample code) is licensed under the Apache License, Version 2.0.
# Author: AWS Professional Services

resource "aws_kms_key" "this" {
  count                              = var.create_kms_key ? 1 : 0
  description                        = var.key_description
  key_usage                          = var.key_usage
  custom_key_store_id                = var.custom_key_store_id
  customer_master_key_spec           = var.customer_master_key_spec
  policy                             = var.policy
  bypass_policy_lockout_safety_check = var.bypass_policy_lockout_safety_check
  deletion_window_in_days            = var.deletion_window_in_days
  is_enabled                         = var.is_enabled
  enable_key_rotation                = var.enable_key_rotation
  rotation_period_in_days            = var.enable_key_rotation ? var.rotation_period_in_days : null
  multi_region                       = var.multi_region

  lifecycle {
    ignore_changes = [ policy ]
  }

  tags                               = var.tags
}

resource "aws_kms_alias" "this" {
  count         = var.alias != null || var.alias_prefix != null ? 1 : 0
  name          = var.alias
  name_prefix   = var.alias_prefix
  target_key_id = local.target_key_id
}

resource "aws_kms_key_policy" "this" {
  count                              = var.create_policy ? 1 : 0
  key_id                             = local.target_key_id
  policy                             = var.policy
  bypass_policy_lockout_safety_check = var.bypass_policy_lockout_safety_check
}