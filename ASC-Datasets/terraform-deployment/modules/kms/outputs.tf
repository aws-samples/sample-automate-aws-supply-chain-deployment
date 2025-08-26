# Software (software, scripts or sample code) is licensed under the Apache License, Version 2.0.
# Author: AWS Professional Services

output "key_id" {
  value       = var.create_kms_key ? aws_kms_key.this[0].id : data.aws_kms_key.this[0].id
  description = "KMS key ID"
}

output "arn" {
  value       = var.create_kms_key ? aws_kms_key.this[0].arn : data.aws_kms_key.this[0].arn
  description = "ARN of KMS key created or provided"
}

output "alias_arn" {
  value       = var.alias != null || var.alias_prefix != null ? aws_kms_alias.this[0].arn : null
  description = "Alias ARN of KMS keys alias created."
}