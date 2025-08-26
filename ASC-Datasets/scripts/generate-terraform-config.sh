# Software (software, scripts or sample code) is licensed under the Apache License, Version 2.0.
# Author: AWS Professional Services

#!/bin/bash

# Change to the root directory of Terraform
cd "$(dirname "$0")/../terraform-deployment" || exit

# Create provider.tf file
cat << EOF > providers.tf
provider "aws" {
  region  = "$REGION"
  default_tags {
    tags = {
      automation  = "terraform"
      repo-name   = "$REPO_NAME"
    }
  }
}
EOF

# Create backend.tf file
cat << EOF > backend.tf
terraform {
  backend "s3" {
    bucket         = "$PROJECT_NAME-$ACCOUNT_ID-$REGION-terraform-state-$ENVIRONMENT"
    use_lockfile   = true
    key            = "$REPO_NAME/terraform.tfstate"
    region         = "$REGION"
    encrypt        = true
  }

  required_version = ">= 1.0.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.5"
    }
    archive = {
      source  = "hashicorp/archive"
      version = "~> 2.5.0"
    }
    null = {
      source  = "hashicorp/null"
      version = "~> 3.1.0"
    }
  }
}
EOF

echo "Successfully generated terraform configurations"