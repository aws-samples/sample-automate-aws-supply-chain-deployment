# Software (software, scripts or sample code) is licensed under the Apache License, Version 2.0.
# Author: AWS Professional Services

module "kms_keys" {
  source  = "./modules/kms"

  for_each = local.kms_keys

  create_kms_key          = try(each.value.create_kms_key, null)
  key_description         = try(each.value.description, null)
  alias                   = try(each.value.alias, null)
  policy                  = try(each.value.kms_policy, null)
  enable_key_rotation     = try(each.value.enable_key_rotation, null)
  rotation_period_in_days = try(each.value.rotation_period_in_days, null)

  tags                    = var.tags
}