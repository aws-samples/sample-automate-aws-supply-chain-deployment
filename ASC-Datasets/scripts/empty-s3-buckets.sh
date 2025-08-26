# Software (software, scripts or sample code) is licensed under the Apache License, Version 2.0.
# Author: AWS Professional Services

#!/bin/bash

# Change to the root directory of Terraform
cd "$(dirname "$0")/../terraform-deployment" || exit

# Check if plan file is provided
if [ -z "$1" ]; then
    echo "Please provide the Terraform plan file (tfplan.out) as an argument."
    exit 1
fi

PLAN_FILE=$1

# Check if the file exists
if [ ! -f "$PLAN_FILE" ]; then
    echo "File $PLAN_FILE does not exist."
    exit 1
fi

# Function to empty a single bucket
empty_bucket() {
    local BUCKET_NAME=$1

    # Check if the bucket exists
    if ! aws s3api head-bucket --bucket "$BUCKET_NAME" 2>/dev/null; then
        echo "Bucket $BUCKET_NAME does not exist. Skipping."
        return
    fi

    echo "Emptying bucket: $BUCKET_NAME"

    # Delete all object versions
    aws s3api list-object-versions --bucket "$BUCKET_NAME" \
      --query 'Versions[].{Key:Key,VersionId:VersionId}' --output json 2>/dev/null |
      jq -c '.[]' 2>/dev/null | while read -r object; do
        key=$(echo "$object" | jq -r '.Key')
        version_id=$(echo "$object" | jq -r '.VersionId')
        aws s3api delete-object --bucket "$BUCKET_NAME" --key "$key" --version-id "$version_id" >/dev/null 2>&1
    done

    # Delete all delete markers
    aws s3api list-object-versions --bucket "$BUCKET_NAME" \
      --query 'DeleteMarkers[].{Key:Key,VersionId:VersionId}' --output json 2>/dev/null |
      jq -c '.[]' 2>/dev/null | while read -r object; do
        key=$(echo "$object" | jq -r '.Key')
        version_id=$(echo "$object" | jq -r '.VersionId')
        aws s3api delete-object --bucket "$BUCKET_NAME" --key "$key" --version-id "$version_id" >/dev/null 2>&1
    done

    # Remove any remaining objects (just in case)
    aws s3 rm s3://"$BUCKET_NAME" --recursive >/dev/null 2>&1

    echo "Bucket $BUCKET_NAME has been emptied."
}

# Function to extract S3 bucket names from Terraform plan
extract_bucket_names() {
    terraform show -json "$PLAN_FILE" > plan.json

    jq -r '.resource_changes[] |
        select(.type == "aws_s3_bucket" and .change.actions[0] == "delete") |
        .change.before.bucket |
        select(. | contains("server-access-logs") | not)' plan.json | sort -u

    rm plan.json
}

# Ensure required environment variables are set
if [ -z "$PROJECT_NAME" ] || [ -z "$ACCOUNT_ID" ] || [ -z "$REGION" ] || [ -z "$ENVIRONMENT" ]; then
    echo "Error: One or more required environment variables are not set."
    echo "Please ensure PROJECT_NAME, ACCOUNT_ID, REGION, and ENVIRONMENT are set."
    exit 1
fi

# Extract bucket names from Terraform plan and empty each bucket
while IFS= read -r bucket; do
    empty_bucket "$bucket"
done < <(extract_bucket_names)

echo "All specified buckets have been processed."