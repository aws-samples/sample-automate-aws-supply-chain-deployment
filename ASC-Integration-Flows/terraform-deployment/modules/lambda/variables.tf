# Software (software, scripts or sample code) is licensed under the Apache License, Version 2.0.
# Author: AWS Professional Services

variable "create" {
  description = "Controls whether resources should be created."
  type        = bool
  default     = true
}

variable "kms_key_arn_s3" {
  description = "Specifies the KMS key to use for S3 object encryption."
  type        = string
  default     = null
}

variable "kms_key_arn_lambda" {
  description = "Specifies the KMS key to use for Lambda Function environment variables encryption."
  type        = string
  default     = null
} 

variable "lambda_role_arn" {
  description = "IAM role arn for Lambda Function"
  type        = string
  default     = null
}

variable "env_var" {
  description = "Environment variables for Lambda Function"
  type        = map(string)
  default     = {}
}

variable "vpc_id" {
  description = "VPC ID for Lambda Function VPC Config"
  type        = string
  default     = null
}

variable "vpc_subnet_ids" {
  description = "Subnet IDs for Lambda Function VPC Config"
  type        = list(string)
  default     = null
}

variable "tags" {
  description = "A mapping of tags to assign to the resource"
  type        = map(string)
  default     = {}
}

variable "function_name" {
  description = "A unique name for your Lambda Function"
  type        = string
  default     = ""
}

variable "handler" {
  description = "Lambda Function entrypoint in your code"
  type        = string
  default     = ""
}

variable "jar_name"{
  description = "Jar file name of lambda code (For Java projects)"
  type        = string
  default     = "sdg-0.1.jar"
}

variable "runtime" {
  description = "Lambda Function runtime"
  type        = string
  default     = ""
}

variable "timeout" {
  description = "The amount of time your Lambda Function has to run in seconds"
  type        = number
  default     = 900
}

variable "memory_size" {
  description = "The memory size of lambda"
  type        = string
  default     = "256"
}

variable "description" {
  description = "Description of your Lambda Function (or Layer)"
  type        = string
  default     = ""
}

variable "s3_bucket" {
  description = "S3 bucket to store artifacts"
  type        = string
  default     = null
}

variable "s3_encryption" {
  description = "The S3 encryption to use"
  type        = string
  default     = "AES256"
}

variable "s3_key_lambda"{
  description = "The filename key to use for S3 object."
  type        = string
  default     = null
}

variable "source_code"{
  description = "The path to the source code for the Lambda Function."
  type        = string
  default     = null
}

variable "create_trigger" {
  description = "Controls whether a trigger should be created for the Lambda Function."
  type        = bool
  default     = false
}

variable "allowed_triggers" {
  description = "Allow other modules to add triggers to the Lambda"
  type        = map(any)
  default     = {}
}

variable "create_kinesis_trigger" {
  description = "Controls whether a Kinesis trigger should be created for the Lambda Function."
  type        = bool
  default     = false
}

variable "kinesis_stream_arn" {
  description = "ARN of the Kinesis stream to use as a trigger."
  type        = string
  default     = null
}

variable "kinesis_starting_position" {
  description = "The position in the stream where AWS Lambda should start reading. Valid values are: TRIM_HORIZON, LATEST, AT_TIMESTAMP."
  type        = string
  default     = "LATEST"
}

variable "kinesis_batch_size" {
  description = "The largest number of records that Lambda will retrieve from the Kinesis stream at the time of invocation."
  type        = number
  default     = 100
}

variable "kinesis_maximum_batching_window_in_seconds" {
  description = "The maximum amount of time to gather records before invoking the function, in seconds. Set to 0 for no batching window."
  type        = number
  default     = 0
}

variable "kinesis_trigger_enabled" {
  description = "Determines if the mapping will be enabled on creation."
  type        = bool
  default     = true
}

variable "kinesis_split_batch_on_error" {
  description = "If the function returns an error, split the batch in two and retry. Default is false."
  type        = bool
  default     = false
}

variable "kinesis_maximum_record_age_in_seconds" {
  description = "The maximum age of a record that Lambda sends to a function for processing. Set to -1 for infinite."
  type        = number
  default     = -1
}

variable "kinesis_retry_attempts" {
  description = "The maximum number of times to retry when the function returns an error. Set to -1 for infinite retries."
  type        = number
  default     = -1
}

variable "kinesis_concurrent_batches_per_shard" {
  description = "The number of batches to process from each shard concurrently. Default is 1."
  type        = number
  default     = 1
}

variable "kinesis_tumbling_window_in_seconds" {
  description = "The duration in seconds of a processing window. Range of 1-900 seconds. Set to null for no tumbling window."
  type        = number
  default     = null
}

variable "kinesis_report_batch_item_failures" {
  description = "Whether to report batch item failures. Set to true to enable reporting batch item failures."
  type        = bool
  default     = false
}

variable "kinesis_filter_criteria" {
  description = "The filter criteria to determine which records should be processed by a Lambda function."
  type = object({
    filters = list(object({
      pattern = string
    }))
  })
  default = null
}

variable "kinesis_destination_config_on_failure" {
  description = "The destination configuration for failed invocations."
  type = object({
    destination_arn = string
  })
  default = null
}

variable "kinesis_scaling_config" {
  description = "The scaling configuration for the event source mapping."
  type = object({
    maximum_concurrency = number
  })
  default = null
}

variable "source_path_lambda" {
  description = "The path to the source code directory for the Lambda Function."
  type        = string
  default     = null
}

variable "lambda_temp_dir" {
  description = "The path to the temp directory for the Lambda Function."
  type        = string
  default     = "lambdaOutput"
}

variable "output_path_lambda_file" {
  description = "The path to the output artifacts for the Lambda Function."
  type        = string
  default     = null
}

variable "create_layer" {
  description = "Controls whether Lambda Layer resource should be created"
  type        = bool
  default     = false
}

variable "layer_arns" {
  description = "List of layers to add to the Lambda Function."
  type        = list(string)
  default     = null
}

variable "inside_vpc" {
  description = "Boolean flag to determine if Lambda should be deployed inside VPC"
  type        = bool
  default     = false
}

variable "create_security_group" {
  description = "Whether to create a security group for RDS"
  type        = bool
  default     = false
}

variable "security_group_id" {
  description = "ID of the security group"
  type        = string
  default     = ""
}

variable "security_group_rules" {
  description = "Security group rules for the cluster"
  type        = any
  default     = {}
}

variable "is_java" {
  description = "Whether the Lambda Function is written in Java"
  type        = bool
  default     = false
}

variable "replace_sg_on_destroy" {
  type         = bool
  default      = false
  description  = "Replace security group on destroy" 
}
