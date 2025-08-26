# Software (software, scripts or sample code) is licensed under the Apache License, Version 2.0.
# Author: AWS Professional Services

data "local_file" "outbound_order_line_schema" {
  filename = "../dataset-schemas/outbound_order_line.json"
}
data "local_file" "calendar_schema" {
  filename = "../dataset-schemas/calendar.json"
}

locals {
  instance_lambda_result = var.instance_operation == "CREATE" ? try(jsondecode(aws_lambda_invocation.create_instance[0].result), {}) : {}
  asc_instance_name = "${var.project_name}-${var.environment}-asc-instance"
  asc_instance_id = try(local.instance_lambda_result["instanceId"], null)

  asc_unique_namespace_keys = toset([
    for k, v in local.asc_datasets_config : "${v.input.namespace}::${v.input.instanceName}"
  ])
  asc_unique_namespace_configs = {
    for ns_id in local.asc_unique_namespace_keys :
    ns_id => {
      namespace    = split("::", ns_id)[0]
      instanceName = split("::", ns_id)[1]
      instanceId   = local.asc_instance_id
      tags         = var.tags
      description  = "This is ${split("::", ns_id)[0]} namespace in ${split("::", ns_id)[1]} ASC instance"
    }
  }

  asc_datasets_config = {
    outbound_order_line = {
      input = {
        schema       = data.local_file.outbound_order_line_schema.content
        name         = "outbound_order_line"
        description  = "This is outbound order line table in asc namespace."
        namespace    = "asc"
        instanceName = local.asc_instance_name
        instanceId   = local.asc_instance_id
        tags         = var.tags
      }
    }
    calendar = {
      input = {
        schema       = data.local_file.calendar_schema.content
        name         = "calendar"
        description  = "This is calendar dataset in asc namespace."
        namespace    = "asc"
        instanceName = local.asc_instance_name
        instanceId   = local.asc_instance_id
        tags         = var.tags
      }
    }
  }

  asc_dataset_lambda_outputs = {
    for idx, outputs in aws_lambda_invocation.create_dataset : idx => jsondecode(outputs.result)
  }
}