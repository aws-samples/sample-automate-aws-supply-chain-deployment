# Software (software, scripts or sample code) is licensed under the Apache License, Version 2.0.
# Author: AWS Professional Services

resource "aws_lambda_function" "this" {
  depends_on                         = [aws_s3_object.lambda_package]

  function_name                      = var.function_name
  description                        = var.description
  role                               = var.lambda_role_arn
  handler                            = var.handler
  memory_size                        = var.memory_size
  runtime                            = var.runtime
  timeout                            = var.timeout
  dynamic "vpc_config" {
    for_each = var.inside_vpc ? [1] : []
    content {
      security_group_ids = [var.security_group_id]
      subnet_ids         = var.vpc_subnet_ids
    }
  }
  replace_security_groups_on_destroy = var.inside_vpc ? var.replace_sg_on_destroy : null

  dynamic "environment" {
    for_each = length(var.env_var) > 0 ? [1] : []
    content {
      variables = var.env_var
    }
  }
  kms_key_arn = length(var.env_var) > 0 ? var.kms_key_arn_lambda : null

  layers                             = var.layer_arns

  s3_bucket                          = var.s3_bucket
  s3_key                             = var.s3_key_lambda
  source_code_hash                   = data.archive_file.lambda_zip.output_base64sha256

  tags                              = var.tags
}

resource "aws_lambda_permission" "lambda_trigger" {
  for_each = { for k, v in var.allowed_triggers : k => v if var.create_trigger }

  function_name          = aws_lambda_function.this.function_name

  statement_id_prefix    = try(each.value.statement_id, each.key)
  action                 = try(each.value.action, "lambda:InvokeFunction")
  principal              = try(each.value.principal, format("%s.amazonaws.com", try(each.value.service, "")))
  principal_org_id       = try(each.value.principal_org_id, null)
  source_arn             = try(each.value.source_arn, null)
  source_account         = try(each.value.source_account, null)
  event_source_token     = try(each.value.event_source_token, null)
  function_url_auth_type = try(each.value.function_url_auth_type, null)

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_lambda_event_source_mapping" "kinesis_trigger" {
  depends_on = [aws_lambda_function.this]
  count      = var.create_kinesis_trigger ? 1 : 0

  event_source_arn                   = var.kinesis_stream_arn
  function_name                      = aws_lambda_function.this.function_name
  starting_position                  = var.kinesis_starting_position
  batch_size                         = var.kinesis_batch_size
  maximum_batching_window_in_seconds = var.kinesis_maximum_batching_window_in_seconds
  enabled                            = var.kinesis_trigger_enabled
  bisect_batch_on_function_error     = var.kinesis_split_batch_on_error
  maximum_record_age_in_seconds      = var.kinesis_maximum_record_age_in_seconds
  maximum_retry_attempts             = var.kinesis_retry_attempts
  parallelization_factor             = var.kinesis_concurrent_batches_per_shard
  tumbling_window_in_seconds         = var.kinesis_tumbling_window_in_seconds
  
  function_response_types            = var.kinesis_report_batch_item_failures ? ["ReportBatchItemFailures"] : []
  
  dynamic "filter_criteria" {
    for_each = var.kinesis_filter_criteria != null ? [var.kinesis_filter_criteria] : []
    
    content {
      dynamic "filter" {
        for_each = filter_criteria.value.filters
        
        content {
          pattern = filter.value.pattern
        }
      }
    }
  }

  dynamic "destination_config" {
    for_each = var.kinesis_destination_config_on_failure != null ? [var.kinesis_destination_config_on_failure] : []
    
    content {
      on_failure {
        destination_arn = destination_config.value.destination_arn
      }
    }
  }

  dynamic "scaling_config" {
    for_each = var.kinesis_scaling_config != null ? [var.kinesis_scaling_config] : []
    
    content {
      maximum_concurrency = scaling_config.value.maximum_concurrency
    }
  }
}

resource "null_resource" "lambda_jar" {
  count = var.is_java ? 1 : 0

  triggers = {
    source_code_hash = data.archive_file.lambda_zip.output_base64sha256
    always_run = timestamp() //For dev purposes
  }

  provisioner "local-exec" {
    command = <<EOT
        echo "creating lambda JAR file"

        cd ${path.root}
        cur_path=${path.cwd}
        mkdir -p ${var.lambda_temp_dir}

        # creating Maven JAR file with dependencies
        cd ${var.source_path_lambda}
        echo "Running mvn clean package..."
        mvn clean package

        # Copy the JAR file to the Lambda output directory
        echo "Copying JAR to Lambda output directory..."
        output_file_name="${replace(var.output_path_lambda_file, ".zip", ".jar")}"
        output_file_path="$cur_path/${var.lambda_temp_dir}/$output_file_name"
        cp target/${var.jar_name} "$output_file_path"

        echo "JAR file copied to output directory"
        
    EOT
  }
}

resource "aws_s3_object" "lambda_package" {
  depends_on = [null_resource.lambda_jar[0]]

  bucket                  = var.s3_bucket
  key                     = var.s3_key_lambda
  source                  = var.is_java ? "${path.root}/${var.lambda_temp_dir}/${replace(var.output_path_lambda_file, ".zip", ".jar")}" : data.archive_file.lambda_zip.output_path
  server_side_encryption  = var.s3_encryption
  kms_key_id              = var.s3_encryption == "aws:kms" ? var.kms_key_arn_s3 : null
  source_hash             = filemd5(data.archive_file.lambda_zip.output_path)
  
  tags                    = var.tags
}
