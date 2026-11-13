# Software (software, scripts or sample code) is licensed under the MIT-0 License.
# Author: AWS Professional Services

locals {
  target_key_id = var.target_key_id != null ? var.target_key_id : aws_kms_key.this[0].id
}