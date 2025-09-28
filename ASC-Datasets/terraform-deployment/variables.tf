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

variable "github_role" {
  type        = string
  default     = null
  description = "ARN of the GitHub role"
}

variable "user_role" {
  type        = string
  default     = ""
  description = "ARN of the user role"
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

variable "instance_operation" {
  type        = string
  default     = "NIL"
  description = "Operation to perform on the ASC instance. Allowed value is CREATE for creation of the instance. Any other value will remove the resource."
}