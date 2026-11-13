# Software (software, scripts or sample code) is licensed under the MIT-0 License.
# Author: AWS Professional Services

output "layer_arn" {
  value = aws_lambda_layer_version.this.arn
  description = "ARN of the layer with its version"
}