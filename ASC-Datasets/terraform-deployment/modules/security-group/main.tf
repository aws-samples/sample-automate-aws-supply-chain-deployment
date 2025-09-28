# Software (software, scripts or sample code) is licensed under the Apache License, Version 2.0.
# Author: AWS Professional Services

# Create Security Group
resource "aws_security_group" "this" {
  name_prefix        = var.sg_name == null ? var.sg_name_prefix : null
  name               = var.sg_name_prefix == null ? var.sg_name : null
  description        = var.sg_desc
  vpc_id             = var.vpc_id

  tags = var.tags
}

#Create security group rules and attach to the above security group
resource "aws_security_group_rule" "this" {
  for_each = { for k, v in var.sg_rules : k => v }

  # required
  type                     = try(each.value.type, "ingress")
  from_port                = try(each.value.from_port, 443)
  to_port                  = try(each.value.to_port, 443)
  protocol                 = try(each.value.protocol, "tcp")
  security_group_id        = aws_security_group.this.id

  # optional
  cidr_blocks              = try(each.value.cidr_blocks, null)
  description              = try(each.value.description, null)
  ipv6_cidr_blocks         = try(each.value.ipv6_cidr_blocks, null)
  prefix_list_ids          = try(each.value.prefix_list_ids, null)
  source_security_group_id = try(each.value.source_security_group_id, null)
  self                     = try(each.value.self, null)
}