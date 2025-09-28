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
