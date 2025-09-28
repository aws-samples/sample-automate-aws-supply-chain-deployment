# Software (software, scripts or sample code) is licensed under the Apache License, Version 2.0.
# Author: AWS Professional Services

#!/bin/bash

# Change to the root directory of Terraform
cd "$(dirname "$0")/../terraform-deployment" || exit

# Function to display error and exit
error_exit() {
    echo "::error::$1"
    exit 1
}

# Check required arguments
if [ "$#" -lt 1 ]; then
    echo "Usage: $0 INFRA_REPO_NAME"
    echo "Example: $0 asc-infrastructure"
    exit 1
fi

mkdir -p tfInputs

for SOURCE_REPO in "$@"; do
    echo "Downloading outputs from $SOURCE_REPO for environment $ENVIRONMENT"

    S3_KEY="$SOURCE_REPO-outputs.tfvars"
    LOCAL_FILE="downloaded-outputs.tfvars"

    # Download the tfvars file from S3
    if ! aws s3 cp "s3://$S3_TERRAFORM_ARTIFACTS_BUCKET_NAME/$S3_KEY" "$LOCAL_FILE"; then
        error_exit "Source outputs not found in S3. Please run the $SOURCE_REPO workflow first."
    fi

    TARGET_FILE="tfInputs/$ENVIRONMENT.tfvars"
    touch "$TARGET_FILE"

    printf "\n# === BEGIN MERGED FROM $SOURCE_REPO ===" >> "$TARGET_FILE"
    cat "$LOCAL_FILE" >> "$TARGET_FILE"
    printf "# === END MERGED FROM $SOURCE_REPO ===\n" >> "$TARGET_FILE"

    echo "Successfully merged source outputs with input variables"

    rm -f "$LOCAL_FILE"
done
