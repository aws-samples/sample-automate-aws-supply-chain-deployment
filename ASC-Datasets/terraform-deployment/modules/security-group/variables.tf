# Software (software, scripts or sample code) is licensed under the Apache License, Version 2.0.
# Author: AWS Professional Services

variable "sg_name" {
  type = string
  description = "Name of the security group."
  default = "security-group-lambda"
}

variable "sg_name_prefix" {
  type = string
  description = "Prefix name of the security group"
  default = null
}

variable "sg_desc" {
  type = string
  description = "Description of the security group"
}

variable "vpc_id" {
  type = string
  description = "ID of the VPC"
}

variable "sg_rules"{
  type = any
  description = "List of security group rules"
  default = {}
}

variable "tags"{
  type = map(string)
  description = "Tags to apply to the security group"
}