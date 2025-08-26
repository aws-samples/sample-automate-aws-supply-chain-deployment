# Software (software, scripts or sample code) is licensed under the Apache License, Version 2.0.
# Author: AWS Professional Services

variable "project_name" {
  type        = string
  default     = "asc-deployment"
  description = "Name of the project"
}

variable "environment" {
  type        = string
  default     = "dev"
  description = "Name of the environment"
}

variable "vpc_config" {
  type = list(object({
    subnets = list(string)
    vpc_id  = string
  }))
  default = [{
    subnets = []
    vpc_id = ""
  }]
  description = "VPC configuration for the resources"
}

variable "tags" {
  type        = map(string)
  default     = {}
  description = "Tags to apply to the resources"
}

variable "layer_temp_dir" {
  type        = string
  default     = "layerOutput"
  description = "Temporary directory for the lambda layer"
}

variable "lambda_temp_dir" {
  type        = string
  default     = "lambdaOutput"
  description = "Temporary directory for the lambda function"
}

###################### Outputs from ASC Deployment repo ###########################

variable "kms_keys" {
  type         = map(string)
  default      = {}
  description  = "Map of KMS keys with their IDs for the resources"
}

variable "s3_buckets" {
  type         = map(string)
  default      = {}
  description  = "Map of S3 buckets with their names for the resources"
}

variable "lambda_sg" {
  type         = string
  default      = ""
  description  = "Security Group of lambda" 
}

variable "asc_instance_id" {
  type         = string
  default      = null
  description  = "AWS Supply Chain Instance ID"
}

variable "asc_dataset_lambda_results" {
  type         = map(object({
    statusCode = number
    body       = string
    namespace  = optional(string)
    name       = optional(string)
    arn        = optional(string)
  }))
  default      = {}
  description  = "Map of ASC Dataset creation results with their ARNs"
}

variable "asc_boto3_layer_arn" {
  type         = string
  default      = ""
  description  = "ARN of the ASC boto3 layer for the lambda function"
}

variable "asc_kms_key_arn_present" {
  type         = bool
  default      = true
  description  = "Whether KMS Key was used for ASC Instance"
}