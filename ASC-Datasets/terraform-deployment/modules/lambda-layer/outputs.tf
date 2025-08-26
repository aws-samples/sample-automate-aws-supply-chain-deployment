# Software (software, scripts or sample code) is licensed under the Apache License, Version 2.0.
# Author: AWS Professional Services

output "layer_arn" {
  value = aws_lambda_layer_version.this.arn
  description = "ARN of the layer with its version"
}