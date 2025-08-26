# Software (software, scripts or sample code) is licensed under the Apache License, Version 2.0.
# Author: AWS Professional Services

variable "create_kms_key" {
  type        = bool
  default     = true
  description = "Whether to create KMS key or not."
}

variable "key_description" {
  type        = string
  default     = "KMS Key managed by terraform"
  description = "Purpose of KMS key"
}

variable "key_usage" {
  type        = string
  default     = null
  description = "Key usage configuration"
}

variable "custom_key_store_id" {
  type        = string
  default     = null
  description = "Customer key store ID"
}

variable "customer_master_key_spec" {
  type        = string
  default     = null
  description = "Customer master key specifications"
}

variable "policy" {
  type        = string
  default     = null
  description = "KMS key policy"
}

variable "bypass_policy_lockout_safety_check" {
  type        = bool
  default     = false
  description = "Whether to bypass policy lockout safety check"
}

variable "deletion_window_in_days" {
  type        = number
  default     = 30
  description = "Number of days to keep key before complete deletion"
}

variable "is_enabled" {
  type        = bool
  default     = true
  description = "Whether to enable KMS key or not."
}

variable "enable_key_rotation" {
  type        = bool
  default     = true
  description = "Whether to enable KMS key rotation or not"
}

variable "rotation_period_in_days" {
  type        = number
  default     = 720
  description = "Number of days after which to rotate the key"
}

variable "multi_region" {
  type        = bool
  default     = false
  description = "Whether to enable multi region configuration or not"
}

variable "tags" {
  type        = map(string)
  default     = {}
  description = "Tags need to be associated with KMS key"
}

variable "alias" {
  type        = string
  default     = null
  description = "Alias name that need to be assigned to KMS key"
}

variable "alias_prefix" {
  type        = string
  default     = null
  description = "Alias prefix that need to be assigned to KMS key"
}

variable "target_key_id" {
  type        = string
  default     = null
  description = "KMS key ID"
}

variable "create_policy" {
  type        = bool
  default     = false
  description = "Whether to create KMS policy or not"
}

variable "ignore_policy_changes" {
  type        = bool
  default     = false
  description = "Whether to ignore changes in KMS policy or not"
}