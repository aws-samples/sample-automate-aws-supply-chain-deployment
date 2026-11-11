# Software (software, scripts or sample code) is licensed under the MIT-0 License.
# Author: AWS Professional Services

data "aws_kms_key" "this" {
  count  = var.create_kms_key ? 0 : 1
  key_id = local.target_key_id
}