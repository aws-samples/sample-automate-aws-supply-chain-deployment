# Software (software, scripts or sample code) is licensed under the MIT-0 License.
# Author: AWS Professional Services

output "sg_id"{
  value       = aws_security_group.this.id
  description = "Security Group ID"
}