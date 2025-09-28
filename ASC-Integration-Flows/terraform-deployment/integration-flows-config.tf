locals {
  asc_instance_id = "${var.asc_instance_id}"
  asc_staging_bucket = "aws-supply-chain-data-${var.asc_instance_id}"

  integration_flows_config = {
    outbound_order_line_source_flow = {
      input = {
        sources        = [
                           {
                             "sourceType": "S3"
                             "sourceName": "outboundorderline"
                             "s3Source": {
                               "bucketName": local.asc_staging_bucket,
                               "prefix": "outbound-order-line-data/",
                               "options": {
                                  "fileType": "CSV"
                                }
                              }
                            }
                          ]
        transformation = {
                           "transformationType": "SQL",
                           "sqlTransformation": {
                              "query": "SELECT * FROM outboundorderline"
                            }
                          }
        target         =  {
                            "targetType": "DATASET",
                            "datasetTarget": {
                                "datasetIdentifier": var.asc_dataset_lambda_results["outbound_order_line"]["arn"],
                                "options": {
                                    "loadType" : "INCREMENTAL",
                                    "dedupeRecords" : true
                                }
                            }
                          }
        name           = "${var.project_name}-${var.environment}-outbound-order-line-flow"
        instanceId     = local.asc_instance_id
        tags           = var.tags
      }
    }
    calendar_source_flow = {
      input = {
        sources        = [
                           {
                             "sourceType": "S3"
                             "sourceName": "calendar"
                             "s3Source": {
                               "bucketName": local.asc_staging_bucket,
                               "prefix": "calendar-data/",
                               "options": {
                                  "fileType": "CSV"
                                }
                              }
                            }
                          ]
        transformation = {
                           "transformationType": "SQL",
                           "sqlTransformation": {
                              "query": "SELECT * FROM calendar"
                            }
                          }
        target         =  {
                            "targetType": "DATASET",
                            "datasetTarget": {
                                "datasetIdentifier": var.asc_dataset_lambda_results["calendar"]["arn"],
                                "options": {
                                    "loadType" : "INCREMENTAL",
                                    "dedupeRecords" : true
                                }
                            }
                          }
        name           = "${var.project_name}-${var.environment}-calendar-flow"
        instanceId     = local.asc_instance_id
        tags           = var.tags
      }
    }
  }

  integration_flows_lambda_outputs = {
    for idx, outputs in aws_lambda_invocation.create_flow : idx => jsondecode(outputs.result)
  }
}