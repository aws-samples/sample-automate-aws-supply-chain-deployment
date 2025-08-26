# Software (software, scripts or sample code) is licensed under the Apache License, Version 2.0.
# Author: AWS Professional Services

variable "bucket_name" {
  type        = string
  description = "Name of the S3 bucekt that need to be created."
}

variable "force_destroy" {
  type        = bool
  default     = false
  description = "Whether to destroy objects in S3 bucket when bucket is destroyed"
}

variable "object_lock_enabled" {
  type        = bool
  default     = false
  description = "Whether S3 bucket should have an Object Lock configuration enabled."
}

variable "logging_config" {
  type        = any
  default     = {}
  description = "Logging configuration of S3 bucket"
}

variable "tags" {
  type        = map(string)
  description = "Map of tags that need to be assigned to S3 bucket"
  default     = {}
}

variable "attach_elb_log_delivery_policy" {
  description = "Controls if S3 bucket should have ELB log delivery policy attached"
  type        = bool
  default     = false
}

variable "attach_lb_log_delivery_policy" {
  description = "Controls if S3 bucket should have ALB/NLB log delivery policy attached"
  type        = bool
  default     = false
}

variable "attach_access_log_delivery_policy" {
  description = "Controls if S3 bucket should have S3 access log delivery policy attached"
  type        = bool
  default     = false
}

variable "attach_deny_insecure_transport_policy" {
  description = "Controls if S3 bucket should have deny non-SSL transport policy attached"
  type        = bool
  default     = false
}

variable "attach_require_latest_tls_policy" {
  description = "Controls if S3 bucket should require the latest version of TLS"
  type        = bool
  default     = true
}

variable "attach_policy" {
  description = "Controls if S3 bucket should have bucket policy attached (set to `true` to use value of `policy` as bucket policy)"
  type        = bool
  default     = false
}

variable "attach_public_policy" {
  description = "Controls if a user defined public bucket policy will be attached (set to `false` to allow upstream to apply defaults to the bucket)"
  type        = bool
  default     = false
}

variable "attach_inventory_destination_policy" {
  description = "Controls if S3 bucket should have bucket inventory destination policy attached."
  type        = bool
  default     = false
}

variable "attach_analytics_destination_policy" {
  description = "Controls if S3 bucket should have bucket analytics destination policy attached."
  type        = bool
  default     = false
}

variable "attach_deny_incorrect_encryption_headers" {
  description = "Controls if S3 bucket should deny incorrect encryption headers policy attached."
  type        = bool
  default     = false
}

variable "attach_deny_incorrect_kms_key_sse" {
  description = "Controls if S3 bucket policy should deny usage of incorrect KMS key SSE."
  type        = bool
  default     = false
}

variable "allowed_kms_key_arn" {
  description = "The ARN of KMS key which should be allowed in PutObject"
  type        = string
  default     = null
}

variable "attach_deny_unencrypted_object_uploads" {
  description = "Controls if S3 bucket should deny unencrypted object uploads policy attached."
  type        = bool
  default     = false
}

variable "acl" {
  description = "(Optional) The canned ACL to apply. Conflicts with `grant`"
  type        = string
  default     = null
}

variable "policy" {
  description = "Additional policies that need to be attached to S3 policy document"
  type        = any
  default     = null
}

variable "acceleration_status" {
  description = "(Optional) Sets the accelerate configuration of an existing bucket. Can be Enabled or Suspended."
  type        = string
  default     = null
}

variable "request_payer" {
  description = "(Optional) Specifies who should bear the cost of Amazon S3 data transfer. Can be either BucketOwner or Requester. By default, the owner of the S3 bucket would incur the costs of any data transfer. See Requester Pays Buckets developer guide for more information."
  type        = string
  default     = null
}

variable "website" {
  description = "Map containing static web-site hosting or redirect configuration."
  type        = any # map(string)
  default     = {}
}

variable "cors_rule" {
  description = "List of maps containing rules for Cross-Origin Resource Sharing."
  type        = any
  default     = []
}

variable "versioning" {
  description = "Map containing versioning configuration."
  type        = map(string)
  default     = {}
}

variable "access_log_delivery_policy_source_buckets" {
  description = "(Optional) List of S3 bucket ARNs wich should be allowed to deliver access logs to this bucket."
  type        = list(string)
  default     = []
}

variable "access_log_delivery_policy_source_accounts" {
  description = "(Optional) List of AWS Account IDs should be allowed to deliver access logs to this bucket."
  type        = list(string)
  default     = []
}

variable "grant" {
  description = "An ACL policy grant. Conflicts with `acl`"
  type        = any
  default     = []
}

variable "owner" {
  description = "Bucket owner's display name and ID. Conflicts with `acl`"
  type        = map(string)
  default     = {}
}

variable "expected_bucket_owner" {
  description = "The account ID of the expected bucket owner"
  type        = string
  default     = null
}

variable "lifecycle_rule" {
  description = "List of maps containing configuration of object lifecycle management."
  type        = any
  default     = []
}

variable "replication_configuration" {
  description = "Map containing cross-region replication configuration."
  type        = any
  default     = {}
}

variable "server_side_encryption_configuration" {
  description = "Map containing server-side encryption configuration."
  type        = any
  default     = {}
}

variable "intelligent_tiering" {
  description = "Map containing intelligent tiering configuration."
  type        = any
  default     = {}
}

variable "object_lock_configuration" {
  description = "Map containing S3 object locking configuration."
  type        = any
  default     = {}
}

variable "metric_configuration" {
  description = "Map containing bucket metric configuration."
  type        = any
  default     = []
}

variable "inventory_configuration" {
  description = "Map containing S3 inventory configuration."
  type        = any
  default     = {}
}

variable "inventory_source_account_id" {
  description = "The inventory source account id."
  type        = string
  default     = null
}

variable "inventory_source_bucket_arn" {
  description = "The inventory source bucket ARN."
  type        = string
  default     = null
}

variable "inventory_self_source_destination" {
  description = "Whether or not the inventory source bucket is also the destination bucket."
  type        = bool
  default     = false
}

variable "analytics_configuration" {
  description = "Map containing bucket analytics configuration."
  type        = any
  default     = {}
}

variable "analytics_source_account_id" {
  description = "The analytics source account id."
  type        = string
  default     = null
}

variable "analytics_source_bucket_arn" {
  description = "The analytics source bucket ARN."
  type        = string
  default     = null
}

variable "analytics_self_source_destination" {
  description = "Whether or not the analytics source bucket is also the destination bucket."
  type        = bool
  default     = false
}

variable "block_public_acls" {
  description = "Whether Amazon S3 should block public ACLs for this bucket."
  type        = bool
  default     = true
}

variable "block_public_policy" {
  description = "Whether Amazon S3 should block public bucket policies for this bucket."
  type        = bool
  default     = true
}

variable "ignore_public_acls" {
  description = "Whether Amazon S3 should ignore public ACLs for this bucket."
  type        = bool
  default     = true
}

variable "restrict_public_buckets" {
  description = "Whether Amazon S3 should restrict public bucket policies for this bucket."
  type        = bool
  default     = true
}

variable "control_object_ownership" {
  description = "Whether to manage S3 Bucket Ownership Controls on this bucket."
  type        = bool
  default     = false
}

variable "object_ownership" {
  description = "Object ownership. Valid values: BucketOwnerEnforced, BucketOwnerPreferred or ObjectWriter. 'BucketOwnerEnforced': ACLs are disabled, and the bucket owner automatically owns and has full control over every object in the bucket. 'BucketOwnerPreferred': Objects uploaded to the bucket change ownership to the bucket owner if the objects are uploaded with the bucket-owner-full-control canned ACL. 'ObjectWriter': The uploading account will own the object if the object is uploaded with the bucket-owner-full-control canned ACL."
  type        = string
  default     = "BucketOwnerEnforced"
}

variable "lambda_notifications" {
  type        = any
  description = "Lambda notification configuraiotns for s3 bucket"
  default     = {}
}

variable "sns_notifications" {
  type        = any
  description = "SNS notification configuration for s3 bucket"
  default     = {}
}

variable "s3_event_bridge_notification" {
  type        = bool
  default     = false
  description = "Whether to enable event bridge notification"
}

variable "sqs_notifications" {
  type        = any
  default     = {}
  description = "S3 SQS notification configuration"
}

variable "destination_bucket" {
  type        = string
  default     = null
  description = "Destination bucket to which replication need to be done"
}

variable "role_path" {
  type        = string
  default     = "/"
  description = "Role path that need to be used"
}

variable "crr_role_name" {
  type        = string
  default     = null
  description = "Name of cross region role"
}

variable "crr_policy_name" {
  type        = string
  default     = null
  description = "Name of CRR policy"
}

variable "permissions_boundary" {
  type        = string
  default     = null
  description = "Permissions boundary that need to be assigned to IAM role"
}

variable "source_kms_key_arn" {
  type        = string
  default     = null
  description = "KMS key Arn of used for encrypting S3"
}

variable "destination_kms_key_arn" {
  type        = string
  default     = null
  description = "KMS key Arn of used for encrypting S3 in destination"
}

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