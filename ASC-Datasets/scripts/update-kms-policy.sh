# Software (software, scripts or sample code) is licensed under the Apache License, Version 2.0.
# Author: AWS Professional Services

#!/bin/bash

# Change to the root directory of Terraform
cd "$(dirname "$0")/../terraform-deployment" || exit

set -euo pipefail

error_exit() {
    echo "::error::$1"
    exit 1
}

STATE_BUCKET="${PROJECT_NAME}-${ACCOUNT_ID}-${REGION}-terraform-state-${ENVIRONMENT}"
LOCAL_STATE_FILE="${REPO_NAME}-terraform.tfstate"
LOCK_FILE="kms-policy-lock.lock"

# Try acquiring lock indefinitely
echo "Checking if lock file exists at $LOCK_FILE in bucket $STATE_BUCKET..."
EMPTY_FILE=$(mktemp)
touch "$EMPTY_FILE"

# Loop until the lock can be acquired
while true; do
    if aws s3api head-object --bucket "$STATE_BUCKET" --key "$LOCK_FILE" >/dev/null 2>&1; then
        echo "Lock file already exists. Waiting for lock to be released..."
        sleep 5
    else
        echo "Attempting to acquire lock..."

        if aws s3api put-object \
            --bucket "$STATE_BUCKET" \
            --key "$LOCK_FILE" \
            --body "$EMPTY_FILE" \
            --if-none-match "*" \
            --content-type "application/json" \
            --metadata timestamp="$(date -u +%Y-%m-%dT%H:%M:%SZ)" \
             >/dev/null 2>&1; then
            echo "Lock acquired."
            break
        else
            echo "Failed to acquire lock. Retrying..."
            sleep 5
        fi
    fi
done

echo "Lock acquired."
rm -f "$EMPTY_FILE"

cleanup() {
  echo "Releasing lock..."
  aws s3api delete-object --bucket "$STATE_BUCKET" --key "$LOCK_FILE"
  rm -f "$LOCAL_STATE_FILE"
}
trap cleanup EXIT

# Pull latest state
echo "Downloading current Terraform state..."
aws s3 cp "s3://$STATE_BUCKET/$REPO_NAME/terraform.tfstate" "$LOCAL_STATE_FILE"

# Extract KMS keys from Terraform outputs in the state file
KMS_KEYS=$(jq -r '.outputs.kms_keys.value' "$LOCAL_STATE_FILE")

# Extract IAM roles
ROLE_ARNS=$(jq -r '.resources[] | select(.type=="aws_iam_role") | .instances[].attributes.arn' "$LOCAL_STATE_FILE" | jq -R . | jq -s .)
echo "👤 IAM Role ARNs:"
echo "$ROLE_ARNS" | jq -r '.[]'

# Iterate over each KMS key and update policy
for KEY_ALIAS in $(echo "$KMS_KEYS" | jq -r 'keys[]'); do
  KEY_ID=$(echo "$KMS_KEYS" | jq -r --arg alias "$KEY_ALIAS" '.[$alias]')
  echo "Updating KMS policy for key ($KEY_ALIAS)..."

  CURRENT_POLICY=$(aws kms get-key-policy --key-id "$KEY_ID" --policy-name default --query Policy --output text)
  echo "$CURRENT_POLICY" | jq . >/dev/null || error_exit "Malformed current policy for $KEY_ID"

  if [[ $(echo "$ROLE_ARNS" | jq 'length') -eq 0 ]]; then
    echo "⚠️ No roles found — removing statement with Sid: ${REPO_NAME}-access if it exists."

    # Remove the statement while preserving and cleaning other statements
    UPDATED_POLICY=$(echo "$CURRENT_POLICY" | jq --arg sid "${REPO_NAME}-access" '
      .Statement |= (
        map(select(.Sid != $sid))
        | map(
            if (.Principal? and .Principal.AWS?) then
              .Principal.AWS |= (
                if type == "array" then
                  map(select(type == "string" and (startswith("arn:aws:iam::") or . == "*")))
                elif type == "string" then
                  if (startswith("arn:aws:iam::") or . == "*") then
                    .
                  else null
                  end
                else null
                end
              )
            else
              .
            end
          )
        | map(
          select(
            (.Principal | has("AWS") | not)
            or (.Principal.AWS | type == "string" and length > 0)
            or (.Principal.AWS | type == "array" and length > 0)
          )
        )
      )
    ')
  else
    echo "✅ Updating policy with $(echo "$ROLE_ARNS" | jq 'length') role(s)."

    # Update while preserving and cleaning other statements
    UPDATED_POLICY=$(echo "$CURRENT_POLICY" | jq --arg sid "${REPO_NAME}-access" --argjson roles "$ROLE_ARNS" '
      .Statement |= (
        map(select(.Sid != $sid))
        | map(
            if (.Principal? and .Principal.AWS?) then
              .Principal.AWS |= (
                if type == "array" then
                  map(select(type == "string" and (startswith("arn:aws:iam::") or . == "*")))
                elif type == "string" then
                  if (startswith("arn:aws:iam::") or . == "*") then
                    .
                  else null
                  end
                else null
                end
              )
            else
              .
            end
          )
        | map(
          select(
            (.Principal | has("AWS") | not)
            or (.Principal.AWS | type == "string" and length > 0)
            or (.Principal.AWS | type == "array" and length > 0)
          )
        )
        + [(
          (
            first(.[] | select(.Sid == $sid)) // {}
          ) + {
            Sid: $sid,
            Effect: "Allow",
            Principal: {
              AWS: ($roles | map(select(startswith("arn:aws:iam::"))))
            },
            Action: [
              "kms:Encrypt",
              "kms:Decrypt",
              "kms:Describe*",
              "kms:ReEncrypt*",
              "kms:GenerateDataKey*"
            ],
            Resource: "*"
          }
        )]
      )
    ')
  fi

  TEMP_POLICY_FILE=$(mktemp)
  echo "$UPDATED_POLICY" > "$TEMP_POLICY_FILE"

  echo "Applying updated policy..."
  aws kms put-key-policy \
    --key-id "$KEY_ID" \
    --policy-name default \
    --policy file://"$TEMP_POLICY_FILE"

  rm -f "$TEMP_POLICY_FILE"
done

echo "KMS policies updated successfully."