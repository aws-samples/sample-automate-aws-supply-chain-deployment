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
}
trap cleanup EXIT

# Extract KMS keys from Terraform Outputs
KMS_KEYS=$(terraform output -json kms_keys || echo '{}')

echo "Checking if ASC KMS key was used in Lambda input..."
ASC_KMS_USED=$(terraform output -raw asc_kms_key_arn_present 2>/dev/null || echo "false")

if [[ "$ASC_KMS_USED" == "true" ]]; then
  echo "✅ ASC Lambda input included a KMS key."

  ASC_KEY_ID=$(echo "$KMS_KEYS" | jq -r --arg alias "asc_staging" '.[$alias]')

  if [[ -z "$ASC_KEY_ID" || "$ASC_KEY_ID" == "null" ]]; then
    error_exit "asc_staging key not found in kms_keys output"
  fi

  echo "🔑 Updating key: $ASC_KEY_ID"

  CURRENT_POLICY=$(aws kms get-key-policy --key-id "$ASC_KEY_ID" --policy-name default --query Policy --output text)
  echo "$CURRENT_POLICY" | jq . >/dev/null || error_exit "Malformed current policy for $ASC_KEY_ID"

  SCN_SID="Allow AWS Supply Chain to access the AWS KMS Key"
  SM_SID="Allow access through SecretManager for all principals in the account that are authorized to use SecretManager"

  # Rebuild statements with clean principals and valid SIDs removed
  CLEANED_POLICY=$(echo "$CURRENT_POLICY" | jq --arg scn_sid "$SCN_SID" --arg sm_sid "$SM_SID" '
    .Statement |= (
      map(select(.Sid != $scn_sid and .Sid != $sm_sid))
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

  SCN_STATEMENT=$(cat <<EOF
{
  "Sid": "Allow AWS Supply Chain to access the AWS KMS Key",
  "Effect": "Allow",
  "Principal": {
    "Service": "scn.$REGION.amazonaws.com"
  },
  "Action": [
    "kms:Encrypt",
    "kms:GenerateDataKeyWithoutPlaintext",
    "kms:ReEncryptFrom",
    "kms:ReEncryptTo",
    "kms:Decrypt",
    "kms:GenerateDataKey",
    "kms:DescribeKey",
    "kms:CreateGrant",
    "kms:RetireGrant"
  ],
  "Resource": "*"
}
EOF
)

  SM_STATEMENT=$(cat <<EOF
{
  "Sid": "Allow access through SecretManager for all principals in the account that are authorized to use SecretManager",
  "Effect": "Allow",
  "Principal": {
    "AWS": "*"
  },
  "Action": [
    "kms:Encrypt",
    "kms:Decrypt",
    "kms:ReEncrypt*",
    "kms:GenerateDataKey*",
    "kms:CreateGrant",
    "kms:DescribeKey",
    "kms:GenerateDataKeyWithoutPlaintext",
    "kms:ReEncryptFrom",
    "kms:ReEncryptTo"
  ],
  "Resource": "*",
  "Condition": {
    "StringEquals": {
      "kms:ViaService": "secretsmanager.$REGION.amazonaws.com",
      "kms:CallerAccount": "$ACCOUNT_ID"
    }
  }
}
EOF
)

  UPDATED_POLICY=$(echo "$CLEANED_POLICY" | jq \
    --argjson scn "$SCN_STATEMENT" \
    --argjson sm "$SM_STATEMENT" '
      .Statement += [$scn, $sm]
    '
  )

  TEMP_POLICY_FILE=$(mktemp)
  echo "$UPDATED_POLICY" > "$TEMP_POLICY_FILE"

  echo "🚀 Applying KMS policy update for ASC staging key..."
  aws kms put-key-policy \
    --key-id "$ASC_KEY_ID" \
    --policy-name default \
    --policy file://"$TEMP_POLICY_FILE"

  rm -f "$TEMP_POLICY_FILE"
  echo "✅ ASC-specific KMS policy updated."

else
  echo "⏩ ASC KMS key was not used. Skipping update."
fi