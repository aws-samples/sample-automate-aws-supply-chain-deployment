# Software (software, scripts or sample code) is licensed under the Apache License, Version 2.0.
# Author: AWS Professional Services

data "aws_caller_identity" "current" {}

data "aws_region" "current" {}

data "aws_partition" "current" {}

data "aws_route_table" "private" {
  count     = length(var.vpc_config[0].subnets)
  subnet_id = var.vpc_config[0].subnets[count.index]
}

data "aws_iam_policy_document" "kms_policy" {
  statement {
    sid = "Enable IAM User Permissions"
    actions = [
      "kms:*"
    ]
    resources = [
      "*"
    ]
    principals {
      type        = "AWS"
      identifiers = compact(concat([
        "arn:aws:iam::${local.account_id}:root",
        var.user_role
      ], var.github_role != null && var.github_role != "" ? [var.github_role] : []))
    }
  }
  statement {
    actions = [
      "kms:Encrypt",
      "kms:Decrypt",
      "kms:ReEncrypt*",
      "kms:GenerateDataKey*",
      "kms:Describe*"
    ]
    resources = [
      "*"
    ]
    principals {
      type        = "Service"
      identifiers = ["logs.${local.region}.amazonaws.com"]
    }
    condition {
      test     = "ArnEquals"
      variable = "kms:EncryptionContext:aws:logs:arn"
      values   = ["arn:aws:logs:${local.region}:${local.account_id}:log-group:*"]
    }
  }
  statement {
    actions = [
      "kms:Encrypt",
      "kms:Decrypt",
      "kms:ReEncrypt*",
      "kms:GenerateDataKey*",
      "kms:Describe*"
    ]
    resources = ["*"]
    principals {
      type        = "Service"
      identifiers = [
        "s3.amazonaws.com"
      ]
    }
  }
}

data "aws_iam_policy_document" "lambda_trust_policy_document" {
  statement {
    actions = [
      "sts:AssumeRole"
    ]
    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
  }
}

data "aws_iam_policy_document" "asc_policy_document" {
  statement {
    actions = [
      "scn:CreateInstance",
      "scn:DescribeInstance",
      "scn:GetInstance",
      "scn:ListInstances",
      "scn:UpdateInstance",
      "scn:CreateDataLakeDataset",
      "scn:GetDataLakeDataset",
      "scn:ListDataLakeDatasets",
      "scn:UpdateDataLakeDataset",
      "scn:DeleteDataLakeDataset",
      "scn:CreateDataLakeNamespace",
      "scn:GetDataLakeNamespace",
      "scn:ListDataLakeNamespaces",
      "scn:UpdateDataLakeNamespace",
      "scn:DeleteDataLakeNamespace",
      "scn:TagResource",
      "scn:UntagResource"
    ]
    resources = [
      "arn:aws:scn:${local.region}:${local.account_id}:instance/*"
    ]
  }
}

data "aws_iam_policy_document" "s3_policy_document" {
  statement {
    actions = [
      "s3:GetObject",
      "s3:PutObject",
      "s3:ListBucket",
      "s3:CreateBucket",
      "s3:PutBucketVersioning",
      "s3:PutBucketObjectLockConfiguration",
      "s3:PutEncryptionConfiguration",
      "s3:PutBucketPolicy",
      "s3:PutLifecycleConfiguration",
      "s3:PutBucketPublicAccessBlock",
      "s3:DeleteObject",
      "s3:ListAllMyBuckets",
      "s3:PutBucketOwnershipControls",
      "s3:PutBucketNotification",
      "s3:PutAccountPublicAccessBlock",
      "s3:PutBucketLogging",
      "s3:PutBucketTagging"
    ]
    resources = [
      "arn:aws:s3:::aws-supply-chain-*"
    ]
  }
}

data "aws_iam_policy_document" "kms_policy_document_asc" {
  statement {
    actions = [
      "kms:CreateGrant",
			"kms:RetireGrant",
			"kms:DescribeKey"
    ]
    resources = [
      "${module.kms_keys["asc_staging"].arn}"
    ]
  }
  statement {
    actions = [
      "kms:ListAliases"
    ]
    resources = [
      "*"
    ]
  }
}

data "aws_iam_policy_document" "chime_policy_document_asc" {
  statement {
    actions = [
      "chime:CreateAppInstance",
      "chime:DeleteAppInstance",
      "chime:PutAppInstanceRetentionSettings",
      "chime:TagResource"
    ]
    resources = [
      "*"
    ]
  }
}

data "aws_iam_policy_document" "event_rule_policy_document_asc" {
  statement {
    actions = [
      "events:DescribeRule",
			"events:PutRule",
			"events:PutTargets"
    ]
    resources = [
      "*"
    ]
  }
}