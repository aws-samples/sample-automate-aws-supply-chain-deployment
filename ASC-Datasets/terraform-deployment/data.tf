# Software (software, scripts or sample code) is licensed under the MIT-0 License.
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
    #checkov:skip=CKV_AWS_109:KMS key policy — Resource "*" refers to this key only
    #checkov:skip=CKV_AWS_111:KMS key policy — Resource "*" refers to this key only
    #checkov:skip=CKV_AWS_356:KMS key policy — Resource "*" refers to this key only
    sid = "Enable IAM User Permissions"
    actions = [
      "kms:CancelKeyDeletion",
      "kms:ConnectCustomKeyStore",
      "kms:CreateAlias",
      "kms:CreateCustomKeyStore",
      "kms:CreateGrant",
      "kms:CreateKey",
      "kms:Decapsulate",
      "kms:Decrypt",
      "kms:DeleteAlias",
      "kms:DeleteCustomKeyStore",
      "kms:DeleteImportedKeyMaterial",
      "kms:DeriveSharedSecret",
      "kms:DescribeCustomKeyStores",
      "kms:DescribeKey",
      "kms:DisableKey",
      "kms:DisableKeyRotation",
      "kms:DisconnectCustomKeyStore",
      "kms:EnableKey",
      "kms:EnableKeyRotation",
      "kms:Encapsulate",
      "kms:Encrypt",
      "kms:GenerateDataKey",
      "kms:GenerateDataKeyPair",
      "kms:GenerateDataKeyPairWithoutPlaintext",
      "kms:GenerateDataKeyWithoutPlaintext",
      "kms:GenerateMac",
      "kms:GenerateRandom",
      "kms:GetKeyLastUsage",
      "kms:GetKeyPolicy",
      "kms:GetKeyRotationStatus",
      "kms:GetParametersForImport",
      "kms:GetPublicKey",
      "kms:ImportKeyMaterial",
      "kms:ListAliases",
      "kms:ListGrants",
      "kms:ListKeyPolicies",
      "kms:ListKeyRotations",
      "kms:ListKeys",
      "kms:ListResourceTags",
      "kms:ListRetirableGrants",
      "kms:PutKeyPolicy",
      "kms:ReEncryptFrom",
      "kms:ReEncryptTo",
      "kms:ReplicateKey",
      "kms:RetireGrant",
      "kms:RevokeGrant",
      "kms:RotateKeyOnDemand",
      "kms:ScheduleKeyDeletion",
      "kms:Sign",
      "kms:TagResource",
      "kms:UntagResource",
      "kms:UpdateAlias",
      "kms:UpdateCustomKeyStore",
      "kms:UpdateKeyDescription",
      "kms:UpdatePrimaryRegion",
      "kms:Verify",
      "kms:VerifyMac"
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
    condition {
      test     = "StringEquals"
      variable = "aws:SourceAccount"
      values   = [local.account_id]
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
  # Scoped to this account via aws:ResourceAccount so the role can never
  # touch a staging bucket owned by a different AWS account.
  # s3:PutBucketPolicy, s3:PutAccountPublicAccessBlock, and s3:ListAllMyBuckets
  # intentionally removed per security review: the Lambda does not need them
  # and PutAccountPublicAccessBlock cannot be resource-scoped.
  statement {
    actions = [
      "s3:GetObject",
      "s3:PutObject",
      "s3:DeleteObject",
      "s3:ListBucket",
      "s3:CreateBucket",
      "s3:PutBucketVersioning",
      "s3:PutBucketObjectLockConfiguration",
      "s3:PutEncryptionConfiguration",
      "s3:PutLifecycleConfiguration",
      "s3:PutBucketPublicAccessBlock",
      "s3:PutBucketOwnershipControls",
      "s3:PutBucketNotification",
      "s3:PutBucketLogging",
      "s3:PutBucketTagging"
    ]
    resources = [
      "arn:aws:s3:::aws-supply-chain-data-*",
      "arn:aws:s3:::aws-supply-chain-data-*/*"
    ]
    condition {
      test     = "StringEquals"
      variable = "aws:ResourceAccount"
      values   = [local.account_id]
    }
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

