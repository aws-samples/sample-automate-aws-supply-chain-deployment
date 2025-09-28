# Software (software, scripts or sample code) is licensed under the Apache License, Version 2.0.
# Author: AWS Professional Services

variable "install_libraries" {
  description = "Does the layer reference itself from requirements.txt/package.json file"
  type        = bool
  default     = false
}

variable "installation_file_name" {
  description = "The name of the file that contains the libraries to be installed"
  type        = string
  default     = "requirements.txt"
}

variable "tags" {
  description = "A mapping of tags to assign to the resource"
  type        = map(string)
  default     = {}
}

variable "kms_key_arn_s3" {
  description = "Specifies the KMS key to use for S3 object encryption."
  type        = string
  default     = null
}

variable "runtime" {
  description = "Lambda Function runtime."
  type        = string
  default     = ""
}

variable "layer_name" {
  type         = string
  default      = ""
  description  = "Lambda layer name" 
}

variable "layer_key" {
  type         = string
  default      = ""
  description  = "Lambda layer key" 
}

variable "source_path_lambda_layer" {
  type         = string
  default      = ""
  description  = "Lambda layer source path" 
}

variable "output_path_layer_file" {
  description = "The filename to the output artifacts for the Lambda layer"
  type        = string
  default     = null
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

variable "layer_temp_dir" {
  description = "The temp directory to store artifacts"
  type        = string
  default     = "layerOutput"
}

variable "create_layer_file" {
  description = "Creates the layer file by zipping the dependencies"
  type        = bool
  default     = true
}

variable "zipped_layer_file" {
  description = "The file path to the output artifacts for the Lambda layer"
  type        = string
  default     = null
}