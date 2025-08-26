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

output "kinesis_event_source_mapping_id" {
  value       = try(aws_lambda_event_source_mapping.kinesis_trigger[0].id, null)
  description = "The identifier of the Kinesis event source mapping, if created"
}

output "kinesis_event_source_mapping_function_arn" {
  value       = try(aws_lambda_event_source_mapping.kinesis_trigger[0].function_arn, null)
  description = "The ARN of the Lambda function the Kinesis event source mapping is sending events to"
}

output "kinesis_event_source_mapping_state" {
  value       = try(aws_lambda_event_source_mapping.kinesis_trigger[0].state, null)
  description = "The state of the Kinesis event source mapping"
}

output "kinesis_event_source_mapping_state_transition_reason" {
  value       = try(aws_lambda_event_source_mapping.kinesis_trigger[0].state_transition_reason, null)
  description = "The reason the Kinesis event source mapping is in its current state"
}
