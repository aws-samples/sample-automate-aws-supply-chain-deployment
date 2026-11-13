#!/bin/bash
# Software (software, scripts or sample code) is licensed under the MIT-0 License.
# Author: AWS Professional Services

set -euo pipefail

AWS_REGION="$REGION"

# Check if S3 bucket exists
if aws s3api head-bucket --bucket "$S3_TERRAFORM_ARTIFACTS_BUCKET_NAME" --region "$AWS_REGION" 2>/dev/null; then
    echo "S3 bucket $S3_TERRAFORM_ARTIFACTS_BUCKET_NAME already exists."
else
    echo "Creating S3 bucket $S3_TERRAFORM_ARTIFACTS_BUCKET_NAME..."
    if [ "$AWS_REGION" = "us-east-1" ]; then
        aws s3api create-bucket \
            --bucket "$S3_TERRAFORM_ARTIFACTS_BUCKET_NAME" \
            --region "$AWS_REGION"
    else
        aws s3api create-bucket \
            --bucket "$S3_TERRAFORM_ARTIFACTS_BUCKET_NAME" \
            --region "$AWS_REGION" \
            --create-bucket-configuration LocationConstraint="$AWS_REGION"
    fi

    # Block all public access on the artifacts bucket
    aws s3api put-public-access-block \
        --bucket "$S3_TERRAFORM_ARTIFACTS_BUCKET_NAME" \
        --public-access-block-configuration \
            BlockPublicAcls=true,IgnorePublicAcls=true,BlockPublicPolicy=true,RestrictPublicBuckets=true

    # Enable versioning on the S3 bucket
    aws s3api put-bucket-versioning \
        --bucket "$S3_TERRAFORM_ARTIFACTS_BUCKET_NAME" \
        --versioning-configuration Status=Enabled

    # Enable default encryption on the S3 bucket (SSE-S3)
    aws s3api put-bucket-encryption \
        --bucket "$S3_TERRAFORM_ARTIFACTS_BUCKET_NAME" \
        --server-side-encryption-configuration '{
            "Rules": [
                {
                    "ApplyServerSideEncryptionByDefault": {
                        "SSEAlgorithm": "AES256"
                    }
                }
            ]
        }'

    # Attach a bucket policy denying any request made over plaintext HTTP
    aws s3api put-bucket-policy \
        --bucket "$S3_TERRAFORM_ARTIFACTS_BUCKET_NAME" \
        --policy "$(cat <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "DenyInsecureTransport",
      "Effect": "Deny",
      "Principal": "*",
      "Action": "s3:*",
      "Resource": [
        "arn:aws:s3:::$S3_TERRAFORM_ARTIFACTS_BUCKET_NAME",
        "arn:aws:s3:::$S3_TERRAFORM_ARTIFACTS_BUCKET_NAME/*"
      ],
      "Condition": {
        "Bool": {
          "aws:SecureTransport": "false"
        }
      }
    }
  ]
}
EOF
)"

    echo "S3 terraform artifacts bucket created successfully with versioning, encryption, Block Public Access, and TLS-only policy."
fi
