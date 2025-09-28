# Software (software, scripts or sample code) is licensed under the Apache License, Version 2.0.
# Author: AWS Professional Services

output "lambda_arn" {
  value       = aws_lambda_function.this.arn
  description = "ARN of the lambda function"
}

output "lambda_invoke_arn" {
  value       = aws_lambda_function.this.invoke_arn
  description = "Invocation ARN of the lambda for API gateway"
}

output "function_name" {
  value       = aws_lambda_function.this.function_name
  description = "Name of the lambda function"
}

output "function_hash" {
  value       = data.archive_file.lambda_zip.output_base64sha256
  description = "Base64-encoded representation of the function's source code, used to trigger updates"
}
