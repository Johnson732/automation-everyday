#!/bin/bash

#################################################
#
# Author: Johnson
# Date: 11-07-25
#
# Script to notify about expiring Azure Key Vault secrets
# within a specified number of days. Supports dry-run mode.
#
# Version: 1.0
#
#################################################


# Fail-fast settings:
# -e: exit on error
# -u: treat unset variables as error
# -o pipefail: fail if any part of a pipe fails
set -euo pipefail


# Prerequisites:
# - Azure CLI installed
# - Logged in via `az login`
# - jq and mail (or msmtp/sendmail) available
# - Correct subscription selected


# Configuration
VAULT_NAME="your-keyvault-name"
EXPIRY_DAYS=15
DRY_RUN=true
ADMIN_EMAIL="security@yourcompany.com"
LOG_FILE="kv_secret_expiry_$(date +%F).log"

echo "Scanning Key Vault '$VAULT_NAME' for secrets expiring in the next $EXPIRY_DAYS days..."
echo "Dry-run mode: $DRY_RUN"
echo "Log file: $LOG_FILE"
echo "" > "$LOG_FILE"


# Get all secret IDs from the vault
secrets=$(az keyvault secret list --vault-name "$VAULT_NAME" --query "[].id" -o tsv) || {
    echo "Failed to retrieve secrets from Key Vault." >&2
    exit 1
}


# Initialize counter
COUNT=0
NOW=$(date +%s)

for secret_id in $secrets; do
    # Get expiration date of the secret
    exp=$(az keyvault secret show --id "$secret_id" --query "attributes.expires" -o tsv || true)

    # Skip if no expiration set
    if [[ "$exp" == "null" || -z "$exp" ]]; then
        continue
    fi

    exp_ts=$(date -d "$exp" +%s || true)
    diff_days=$(( (exp_ts - NOW) / 86400 ))

    if (( diff_days <= EXPIRY_DAYS )); then
        secret_name=$(basename "$secret_id")

        echo "Secret '$secret_name' expires in $diff_days days ($exp)" | tee -a "$LOG_FILE"

        if [ "$DRY_RUN" = false ]; then
            echo "Sending email alert for $secret_name to $ADMIN_EMAIL..."
            echo "Secret '$secret_name' in Key Vault '$VAULT_NAME' will expire in $diff_days days on $exp." \
                | mail -s "Secret Expiry Alert: $secret_name" "$ADMIN_EMAIL"
        fi

        COUNT=$((COUNT + 1))
    fi
done


echo ""
echo "Total secrets nearing expiry: $COUNT" | tee -a "$LOG_FILE"

if [ "$DRY_RUN" = true ]; then
    echo "Dry-run enabled. No email notifications were sent." | tee -a "$LOG_FILE"
fi


################################################################################
# Script Breakdown & Explanation
#
# set -euo pipefail:
#   Ensures script exits on errors, undefined variables, or broken pipes.
#
# az keyvault secret list --vault-name ...:
#   Fetches all secret identifiers from the specified Key Vault.
#
# az keyvault secret show --id ...:
#   Retrieves each secret's metadata including expiration date.
#
# date -d "$exp" +%s:
#   Converts expiration date to epoch timestamp for comparison.
#
# DRY_RUN=true:
#   Prevents actual email sending — useful for testing and safety.
#
# mail -s ...:
#   Sends notification using system mail. Replace with msmtp/sendmail if needed.
#
# Logging:
#   Writes results and warnings to a timestamped log for audit purposes.
#
# Why This Script Matters:
#   Expired secrets cause outages and security gaps. This script allows
#   proactive rotation and compliance hygiene in any cloud-first org.
################################################################################
