# Software (software, scripts or sample code) is licensed under the Apache License, Version 2.0.
# Author: AWS Professional Services

data "aws_caller_identity" "current" {}

data "aws_region" "current" {}

data "aws_partition" "current" {}

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
      "scn:DescribeInstance",
      "scn:GetInstance",
      "scn:ListInstances",
      "scn:CreateDataIntegrationFlow",
      "scn:GetDataIntegrationFlow",
      "scn:ListDataIntegrationFlows",
      "scn:UpdateDataIntegrationFlow",
      "scn:DeleteDataIntegrationFlow",
      "scn:TagResource",
      "scn:UntagResource"
    ]
    resources = [
      "arn:aws:scn:${local.region}:${local.account_id}:instance/*"
    ]
  }
}