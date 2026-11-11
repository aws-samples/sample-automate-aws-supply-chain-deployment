# Software (software, scripts or sample code) is licensed under the MIT-0 License.
# Author: AWS Professional Services

terraform {
  required_version = ">= 1.0.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.5"
    }
  }
}
