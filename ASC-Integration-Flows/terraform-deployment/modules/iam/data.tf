# Software (software, scripts or sample code) is licensed under the Apache License, Version 2.0.
# Author: AWS Professional Services

data "aws_iam_role" "this" {
  count = var.create_role ? 0 : var.role_name != null ? 1 : 0
  name  = var.role_name
}

data "aws_iam_policy_document" "iam_pass_role_policy_document" {
  statement {
    actions = [
      "iam:PassRole"
    ]
    resources = [
      aws_iam_role.this[0].arn
    ]
  }
}