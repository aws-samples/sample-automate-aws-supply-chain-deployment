# Software (software, scripts or sample code) is licensed under the Apache License, Version 2.0.
# Author: AWS Professional Services

output "lambda_sg" {
  description = "Security Group ID for Lambda"
  value = module.lambda_sg.sg_id
}

output "kms_keys" {
  description = "Map of KMS key names with their IDs"
  value = {
    for idx, keys in module.kms_keys : idx => keys.key_id
  }
  sensitive = true
}

output "s3_buckets" {
  description = "Map of S3 bucket names with their actual name"
  value = {
    for idx, buckets in module.s3_buckets : idx => buckets.bucket_name
  }
}

output "asc_dataset_lambda_results" {
  description = "Results of ASC dataset lambda executions"
  value = {
    for idx, results in aws_lambda_invocation.create_dataset : idx => jsondecode(results.result)
  }
}

output "asc_boto3_layer_arn" {
  value       = module.asc_layer_boto3.layer_arn
  description = "ARN of the boto3 layer for ASC"
}

output "asc_instance_id" {
  value       = local.asc_instance_id
  description = "ASC Instance ID"
}

output "asc_kms_key_arn_present" {
  description = "True if kmsKeyArn was passed in the ASC Instance Lambda input"
  value = (
    var.instance_operation == "CREATE" ?
    contains(
      keys(jsondecode(aws_lambda_invocation.create_instance[0].input)),
      "kmsKeyArn"
    ) : false
  )
}