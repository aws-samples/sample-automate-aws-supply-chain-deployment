# Software (software, scripts or sample code) is licensed under the Apache License, Version 2.0.
# Author: AWS Professional Services

variable "create_role" {
  type        = bool
  description = "Whether to create IAM role or not."
  default     = true
}

variable "trust_policy" {
  type        = string
  default     = null
  description = "Trust policy that need to be associated with the role"
}

variable "role_name" {
  type        = string
  default     = null
  description = "Name of IAM role that need to be created"
}

variable "name_prefix" {
  type        = string
  default     = null
  description = "Random role name with specific prefix"
}

variable "force_detach_policies" {
  type        = bool
  default     = false
  description = "Whether to forcefully detach policy when destroying role"
}

variable "role_path" {
  type        = string
  default     = "/"
  description = "Path that need to be used while creating role"
}

variable "description" {
  type        = string
  description = "IAM role description to identify the purpose of the role"
  default     = null
}

variable "max_session_duration" {
  type        = number
  default     = 3600
  description = "Maximum time period for which session should be active"
}

variable "tags" {
  type        = map(string)
  description = "Map of tags that need to be associated with IAM role"
  default     = {}
}

variable "policy_configs" {
  type        = any
  description = "List of policy configs using which policies need to be created and assigned to roles"
  default     = {}
}

variable "inline_policy" {
  type        = any
  default     = []
  description = "List of map of inline policies"
}

variable "managed_policy_arns" {
  type        = list(string)
  default     = []
  description = "List of managed inline policies"
}

variable "permissions_boundary_arn" {
  type        = string
  default     = null
  description = "ARN of the policy that is used to set the permissions boundary for the role"
}

variable "create_pass_role_policy" {
  type        = bool
  default     = false
  description = "Whether to create pass role or not"
}

variable "pass_role_policy_name" {
  type        = string
  default     = "pass_role_policy"
  description = "Name of the pass role policy"
}