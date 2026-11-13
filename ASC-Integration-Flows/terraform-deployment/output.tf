# Software (software, scripts or sample code) is licensed under the MIT-0 License.
# Author: AWS Professional Services

output "source_flows_lambda_results" {
  description = "Results of Source flow Lambda execution"
  value = {
    for idx, results in aws_lambda_invocation.create_flow : idx => jsondecode(results.result)
  }
}