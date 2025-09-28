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

    # Download the source repo outputs
    if ! jf rt download \
        --flat=false \
        --recursive=true \
        "$JFROG_ARTIFACTS_REPO/$SOURCE_REPO/$ENVIRONMENT/reusable-outputs/$SOURCE_REPO-outputs.tfvars" \
        "downloaded-outputs.tfvars"; then
        error_exit "Source outputs not found. Please run the $SOURCE_REPO workflow first."
    fi

    mv $SOURCE_REPO/$ENVIRONMENT/reusable-outputs/* ./
    rm -rf $SOURCE_REPO

     # Merge with existing input vars
    TARGET_FILE="tfInputs/$ENVIRONMENT.tfvars"

    # Ensure target file exists
    touch "$TARGET_FILE"

    if [ -f "downloaded-outputs.tfvars" ]; then
        echo -e "\n# === BEGIN MERGED FROM $SOURCE_REPO ===" >> "$TARGET_FILE"
        cat "downloaded-outputs.tfvars" >> "$TARGET_FILE"
        echo -e "# === END MERGED FROM $SOURCE_REPO ===\n" >> "$TARGET_FILE"

        echo "Successfully merged source outputs with input variables"
    else
        error_exit "Failed to process source outputs from $SOURCE_REPO"
    fi
    
    rm -f downloaded-outputs.tfvars
done