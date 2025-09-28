# Software (software, scripts or sample code) is licensed under the Apache License, Version 2.0.
# Author: AWS Professional Services

#Create Security Group for Lambda Functions
module "lambda_sg"{
  source = "./modules/security-group"

  sg_name = "${var.project_name}-${var.environment}-lambda-sg"
  sg_desc = "Security group for Lambda functions"
  vpc_id = var.vpc_config[0].vpc_id
  sg_rules = {
    egress1 = {
      type                     = "egress"
      description              = "Allow outbound traffic to VPC endpoints SG"
      from_port                = 443
      to_port                  = 443
      protocol                 = "tcp"
      source_security_group_id = module.vpc_endpoints_sg.sg_id
    }
    egress2 = {
      type                      = "egress"
      description               = "Allow egress to S3"
      from_port                 = 443
      to_port                   = 443
      protocol                  = "tcp"
      prefix_list_ids           = [data.aws_prefix_list.s3.id]
    }
  }

  tags = var.tags
}

#Create Security Group for VPC Endpoint
module "vpc_endpoints_sg"{
  source = "./modules/security-group"
  
  sg_name = "${var.project_name}-${var.environment}-vpc-endpoints-sg"
  sg_desc = "Security group for VPC endpoints"
  vpc_id = var.vpc_config[0].vpc_id
  sg_rules = {
    ingress1={
      type                     = "ingress"
      description              = "Allow inbound traffic"
      from_port                = 443
      to_port                  = 443
      protocol                 = "tcp"
      source_security_group_id = module.lambda_sg.sg_id
    }
    egress1={
      type                     = "egress"
      description              = "Allow outbound traffic"
      from_port                = 443
      to_port                  = 443
      protocol                 = "tcp"
      source_security_group_id = module.lambda_sg.sg_id
    }
  }

  tags = var.tags
}