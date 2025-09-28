# Software (software, scripts or sample code) is licensed under the Apache License, Version 2.0.
# Author: AWS Professional Services

# Create a VPC Gateway Endpoint for S3
data "aws_prefix_list" "s3" {
  name = "com.amazonaws.${local.region}.s3"
}

#Create a VPC Gateway endpoint for S3
resource "aws_vpc_endpoint" "s3-endpoint" {
  vpc_id       = var.vpc_config[0].vpc_id
  service_name = "com.amazonaws.${local.region}.s3"
  
  vpc_endpoint_type = "Gateway"
  route_table_ids = distinct([for rt in data.aws_route_table.private : rt.route_table_id])
  
  tags = var.tags
}

resource "aws_vpc_endpoint" "interface_endpoints" {
  for_each = local.vpc_interface_endpoints

  vpc_id               = var.vpc_config[0].vpc_id
  service_name         = "com.amazonaws.${local.region}.${each.value}"
  vpc_endpoint_type    = "Interface"
  private_dns_enabled  = true
  subnet_ids           = var.vpc_config[0].subnets
  security_group_ids   = [module.vpc_endpoints_sg.sg_id]

  tags                 = var.tags
}