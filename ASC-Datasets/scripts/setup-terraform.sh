# Software (software, scripts or sample code) is licensed under the Apache License, Version 2.0.
# Author: AWS Professional Services

#!/bin/bash

S3_BUCKET_NAME="$PROJECT_NAME-$ACCOUNT_ID-$REGION-terraform-state-$ENVIRONMENT"
AWS_REGION="$REGION"

# Check if S3 bucket exists
if aws s3api head-bucket --bucket $S3_BUCKET_NAME --region $AWS_REGION 2>/dev/null; then
    echo "S3 bucket $S3_BUCKET_NAME already exists."
else
    echo "Creating S3 bucket $S3_BUCKET_NAME..."
    if [ "$AWS_REGION" = "us-east-1" ]; then
        aws s3api create-bucket \
            --bucket $S3_BUCKET_NAME \
            --region $AWS_REGION
    else
        aws s3api create-bucket \
            --bucket $S3_BUCKET_NAME \
            --region $AWS_REGION \
            --create-bucket-configuration LocationConstraint=$AWS_REGION
    fi
    
    # Enable versioning on the S3 bucket
    aws s3api put-bucket-versioning \
        --bucket $S3_BUCKET_NAME \
        --versioning-configuration Status=Enabled

    # Enable default encryption on the S3 bucket (SSE-S3)
    aws s3api put-bucket-encryption \
        --bucket $S3_BUCKET_NAME \
        --server-side-encryption-configuration '{
            "Rules": [
                {
                    "ApplyServerSideEncryptionByDefault": {
                        "SSEAlgorithm": "AES256"
                    }
                }
            ]
        }'

    echo "S3 bucket created successfully with versioning and default encryption enabled."
fi

echo "Setup complete. You can now run your Terraform commands."
