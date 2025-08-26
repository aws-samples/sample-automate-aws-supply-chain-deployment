# Software (software, scripts or sample code) is licensed under the Apache License, Version 2.0.
# Author: AWS Professional Services

module "s3_buckets" {
  source = "./modules/s3"

  for_each = local.s3_buckets

  bucket_name                                 = try(each.value.bucket_name, null)
  versioning                                  = try(each.value.versioning, null)
  server_side_encryption_configuration        = {
    rule                                      = {
      apply_server_side_encryption_by_default = try(each.value.encryption, null)
    }
  }
  lifecycle_rule                              = try(each.value.lifecycle_rule, null)
  logging_config                              = try(each.value.logging_config, {})
  control_object_ownership                    = try(each.value.control_object_ownership, false)
  object_ownership                            = try(each.value.object_ownership, null)
  attach_access_log_delivery_policy           = try(each.value.attach_access_log_delivery_policy, false)
  access_log_delivery_policy_source_buckets   = try(each.value.access_log_delivery_policy_source_buckets, null)
  force_destroy                               = try(each.value.force_destroy, false)

  tags = var.tags
}