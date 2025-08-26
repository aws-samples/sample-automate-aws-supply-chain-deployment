# Software (software, scripts or sample code) is licensed under the Apache License, Version 2.0.
# Author: AWS Professional Services

#!/bin/bash

S3_BUCKET_NAME="$PROJECT_NAME-$ACCOUNT_ID-$REGION-terraform-state-$ENVIRONMENT"
AWS_REGION="$REGION"

# Function to check if a resource exists
resource_exists() {
    case $1 in
        "s3")
            aws s3api head-bucket --bucket $S3_BUCKET_NAME --region $AWS_REGION 2>/dev/null
            ;;
    esac
    return $?
}

# Check if S3 bucket exists
if ! resource_exists "s3"; then
    echo "S3 bucket $S3_BUCKET_NAME does not exist."
    exit 1
fi

echo "S3 bucket exist. Terraform destroy should proceed."
exit 0