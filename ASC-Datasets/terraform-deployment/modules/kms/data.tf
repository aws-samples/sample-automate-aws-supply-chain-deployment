# Software (software, scripts or sample code) is licensed under the Apache License, Version 2.0.
# Author: AWS Professional Services

data "aws_kms_key" "this" {
  count  = var.create_kms_key ? 0 : 1
  key_id = local.target_key_id
}