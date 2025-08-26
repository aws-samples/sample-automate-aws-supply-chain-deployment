# Software (software, scripts or sample code) is licensed under the Apache License, Version 2.0.
# Author: AWS Professional Services

resource "aws_s3_object" "outbound_order_line_data_file" {
  depends_on    = [ aws_lambda_invocation.create_flow ]

  bucket                 = local.asc_staging_bucket
  key                    = "outbound-order-line-data/sample-data.csv"
  source                 = "${path.root}/../sample-data/outbound_order_line_data.csv"
  server_side_encryption = "aws:kms"
  kms_key_id             = "arn:aws:kms:${local.region}:${local.account_id}:key/${var.kms_keys["asc_staging"]}"
  source_hash            = filemd5("${path.root}/../sample-data/outbound_order_line_data.csv")

  tags = var.tags
}

resource "aws_s3_object" "calendar_data_file" {
  depends_on    = [ aws_lambda_invocation.create_flow ]
  
  bucket                 = local.asc_staging_bucket
  key                    = "calendar-data/sample-data.csv"
  source                 = "${path.root}/../sample-data/calendar_data.csv"
  server_side_encryption = "aws:kms"
  kms_key_id             = "arn:aws:kms:${local.region}:${local.account_id}:key/${var.kms_keys["asc_staging"]}"
  source_hash            = filemd5("${path.root}/../sample-data/calendar_data.csv")

  tags = var.tags
}