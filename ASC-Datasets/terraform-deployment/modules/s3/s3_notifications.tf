# Software (software, scripts or sample code) is licensed under the Apache License, Version 2.0.
# Author: AWS Professional Services

resource "aws_s3_bucket_notification" "this" {
  depends_on = [aws_lambda_permission.this]
  count      = length(keys(var.lambda_notifications)) != 0 || length(keys(var.sns_notifications)) != 0 || var.s3_event_bridge_notification || length(var.sqs_notifications) != 0 ? 1 : 0
  bucket     = aws_s3_bucket.this.id
  dynamic "lambda_function" {
    for_each = var.lambda_notifications

    content {
      id                  = try(lambda_function.value.id, lambda_function.key)
      lambda_function_arn = lambda_function.value.function_arn
      events              = lambda_function.value.events
      filter_prefix       = try(lambda_function.value.filter_prefix, null)
      filter_suffix       = try(lambda_function.value.filter_suffix, null)
    }
  }
  dynamic "queue" {
    for_each = var.sqs_notifications

    content {
      id            = try(queue.value.id, queue.key)
      queue_arn     = queue.value.queue_arn
      events        = queue.value.events
      filter_prefix = try(queue.value.filter_prefix, null)
      filter_suffix = try(queue.value.filter_suffix, null)
    }
  }
  dynamic "topic" {
    for_each = var.sns_notifications

    content {
      id            = try(topic.value.id, topic.key)
      topic_arn     = topic.value.topic_arn
      events        = topic.value.events
      filter_prefix = try(topic.value.filter_prefix, null)
      filter_suffix = try(topic.value.filter_suffix, null)
    }
  }
  eventbridge = var.s3_event_bridge_notification
}

resource "aws_lambda_permission" "this" {
  for_each            = var.lambda_notifications
  statement_id_prefix = "AllowLambdaS3BucketNotification-"
  action              = "lambda:InvokeFunction"
  function_name       = each.value.function_name
  qualifier           = try(each.value.qualifier, null)
  principal           = "s3.amazonaws.com"
  source_arn          = aws_s3_bucket.this.arn
  source_account      = try(each.value.source_account, null)
}