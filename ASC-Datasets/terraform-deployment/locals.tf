# Software (software, scripts or sample code) is licensed under the Apache License, Version 2.0.
# Author: AWS Professional Services

locals {
  aws_partition = data.aws_partition.current.partition
  account_id    = data.aws_caller_identity.current.account_id
  region        = data.aws_region.current.name
  
  kms_policy     = data.aws_iam_policy_document.kms_policy.json

  kms_keys = {
    artifacts = {
      create_kms_key          = true
      description             = "KMS key for ASC Deployment artifacts bucket"
      alias                   = "alias/${var.project_name}-kms-artifacts-${var.environment}"
      kms_policy              = local.kms_policy
      enable_key_rotation     = true
      rotation_period_in_days = 720
    }
    asc_staging = {
      create_kms_key          = true
      description             = "KMS key for ASC Deployment staging bucket"
      alias                   = "alias/${var.project_name}-kms-asc-staging-${var.environment}"
      kms_policy              = local.kms_policy
      enable_key_rotation     = true
      rotation_period_in_days = 720
    }
  }

  s3_buckets = {
    artifacts = {
      bucket_name              = "${var.project_name}-${local.account_id}-${local.region}-artifacts-${var.environment}"
      versioning               = {
        enabled                = true
      }
      encryption               = {
        kms_master_key_id      = module.kms_keys["artifacts"].arn
        sse_algorithm          = "aws:kms"
      }
      lifecycle_rule = [
        {
          id      = "abort-multipart-uploads"
          enabled = true
          abort_incomplete_multipart_upload_days = 7
        }
      ]
      control_object_ownership = true
      object_ownership         = "BucketOwnerEnforced"
      logging_config           = {
        logging_bucket_name    = "${var.project_name}-${local.account_id}-${local.region}-server-access-logs-${var.environment}"
        prefix                 = "${var.project_name}-${local.account_id}-${local.region}-artifacts-${var.environment}-logs/"
      }
    }
    server_access_log = {
      bucket_name                               = "${var.project_name}-${local.account_id}-${local.region}-server-access-logs-${var.environment}"
      versioning                                = {
        enabled                                 = true
      }
      encryption                                = {
        sse_algorithm                           = "AES256"
      }
      lifecycle_rule = [
        {
          id      = "abort-multipart-uploads"
          enabled = true
          abort_incomplete_multipart_upload_days = 7
        }
      ]
      control_object_ownership                  = true
      object_ownership                          = "BucketOwnerEnforced"
      attach_access_log_delivery_policy         = true
      access_log_delivery_policy_source_buckets = [
        "arn:aws:s3:::${var.project_name}-${local.account_id}-${local.region}-artifacts-${var.environment}"
      ]
      force_destroy = true
    }
  }

  vpc_interface_endpoints = {
    kms                  = "kms"
    scn                  = "scn"
    logs                 = "logs"
    lakeformation        = "lakeformation"
  }

  lambda_asc_policy_configs = {
    asc_access_config = {
      policy_name_prefix      = "${var.project_name}-${var.environment}-iam-policy-lambda-asc-${data.aws_region.current.name}"
      description             = "IAM policy to allow lambda function to perform asc operations"
      policy_statement        = data.aws_iam_policy_document.asc_policy_document.json
    }
    s3_access_config = {
      policy_name_prefix      = "${var.project_name}-${var.environment}-iam-policy-lambda-s3-${data.aws_region.current.name}"
      description             = "IAM policy to allow lambda function to perform S3 operations"
      policy_statement        = data.aws_iam_policy_document.s3_policy_document.json
    }
    kms_asc_access_config = {
      policy_name_prefix      = "${var.project_name}-${var.environment}-iam-policy-lambda-kms-${data.aws_region.current.name}"
      description             = "IAM policy to allow lambda function to perform KMS operations on ASC key"
      policy_statement        = data.aws_iam_policy_document.kms_policy_document_asc.json
    }
    chime_asc_access_config = {
      policy_name_prefix      = "${var.project_name}-${var.environment}-iam-policy-lambda-chime-${data.aws_region.current.name}"
      description             = "IAM policy to allow lambda function to perform chime operations"
      policy_statement        = data.aws_iam_policy_document.chime_policy_document_asc.json
    }
    event_rule_asc_access_config = {
      policy_name_prefix      = "${var.project_name}-${var.environment}-iam-policy-lambda-events-${data.aws_region.current.name}"
      description             = "IAM policy to allow lambda function to perform event rule operations"
      policy_statement        = data.aws_iam_policy_document.event_rule_policy_document_asc.json
    }
  }
}