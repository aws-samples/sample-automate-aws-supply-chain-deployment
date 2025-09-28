# Software (software, scripts or sample code) is licensed under the Apache License, Version 2.0.
# Author: AWS Professional Services

output "role_arn" {
  value       = var.create_role ? aws_iam_role.this[0].arn : try(data.aws_iam_role.this[0].arn, null)
  description = "ARN of IAM role"
}

output "policy_arns" {
  value       = { for key in keys(var.policy_configs) : key => aws_iam_policy.this[key].arn }
  description = "Map of policy ARN's created"
}

output "role_name" {
  value       = var.create_role ? aws_iam_role.this[0].name : try(var.role_name, null)
  description = "Name of IAM role"
}