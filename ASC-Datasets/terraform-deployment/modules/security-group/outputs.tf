# Software (software, scripts or sample code) is licensed under the Apache License, Version 2.0.
# Author: AWS Professional Services

output "sg_id"{
  value       = aws_security_group.this.id
  description = "Security Group ID"
}