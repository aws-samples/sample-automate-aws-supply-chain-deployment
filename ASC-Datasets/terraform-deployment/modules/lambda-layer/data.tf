# Software (software, scripts or sample code) is licensed under the Apache License, Version 2.0.
# Author: AWS Professional Services

data "aws_caller_identity" "current" {}

data "aws_region" "current" {}

data "aws_partition" "current" {}

data "archive_file" "lambda_layer_zip" {
  count       = var.create_layer_file ? 1 : 0

  type        = "zip"
  source_dir  = "${path.root}/${var.source_path_lambda_layer}"
  output_path = "${path.root}/${var.layer_temp_dir}/hash/${var.output_path_layer_file}"
}