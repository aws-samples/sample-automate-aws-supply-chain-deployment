# Software (software, scripts or sample code) is licensed under the Apache License, Version 2.0.
# Author: AWS Professional Services

output "bucket_name" {
  value       = aws_s3_bucket.this.id
  description = "Name of S3 bucket that is created"
}

output "bucket_arn" {
  value       = aws_s3_bucket.this.arn
  description = "Arn of S3 bucket that is created"
}