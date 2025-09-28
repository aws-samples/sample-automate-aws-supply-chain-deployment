# Software (software, scripts or sample code) is licensed under the Apache License, Version 2.0.
# Author: AWS Professional Services

#!/bin/bash

BUCKET_NAME="$PROJECT_NAME-$ACCOUNT_ID-$REGION-terraform-state-$ENVIRONMENT"

# Check if the bucket exists
if ! aws s3api head-bucket --bucket "$BUCKET_NAME" 2>/dev/null; then
    echo "Bucket $BUCKET_NAME does not exist. Skipping."
    exit 0
fi

echo "Emptying bucket: $BUCKET_NAME"

# Function to delete all versions of all objects
delete_all_versions() {
    local bucket="$1"
    local versions
    local delete_markers
    
    versions=$(aws s3api list-object-versions --bucket "$bucket" --output json --query 'Versions[].{Key:Key,VersionId:VersionId}')
    delete_markers=$(aws s3api list-object-versions --bucket "$bucket" --output json --query 'DeleteMarkers[].{Key:Key,VersionId:VersionId}')

    if [ -n "$versions" ] && [ "$versions" != "null" ]; then
        echo "$versions" | jq -c '.[]' | while read -r object; do
            key=$(echo "$object" | jq -r '.Key')
            version_id=$(echo "$object" | jq -r '.VersionId')
            echo "Deleting object: $key (version $version_id)"
            aws s3api delete-object --bucket "$bucket" --key "$key" --version-id "$version_id"
        done
    fi

    if [ -n "$delete_markers" ] && [ "$delete_markers" != "null" ]; then
        echo "$delete_markers" | jq -c '.[]' | while read -r object; do
            key=$(echo "$object" | jq -r '.Key')
            version_id=$(echo "$object" | jq -r '.VersionId')
            echo "Deleting delete marker: $key (version $version_id)"
            aws s3api delete-object --bucket "$bucket" --key "$key" --version-id "$version_id"
        done
    fi
}

# Delete all versions and delete markers
echo "Removing all object versions and delete markers from $BUCKET_NAME..."
delete_all_versions "$BUCKET_NAME"

# Remove any remaining objects (just in case)
echo "Removing any remaining objects from $BUCKET_NAME..."
aws s3 rm s3://"$BUCKET_NAME" --recursive

echo "Bucket $BUCKET_NAME should now be empty."

# Delete the bucket
echo "Attempting to delete bucket $BUCKET_NAME..."
if aws s3api delete-bucket --bucket "$BUCKET_NAME" --region "$REGION"; then
    echo "Bucket $BUCKET_NAME has been successfully deleted."
else
    echo "Failed to delete bucket $BUCKET_NAME. Please check for any remaining objects or permissions issues."
    echo "Listing any remaining objects:"
    aws s3api list-object-versions --bucket "$BUCKET_NAME" --output json
fi