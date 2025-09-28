# Software (software, scripts or sample code) is licensed under the Apache License, Version 2.0.
# Author: AWS Professional Services

locals {
  target_key_id = var.target_key_id != null ? var.target_key_id : aws_kms_key.this[0].id
}