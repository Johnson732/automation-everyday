#!/bin/bash

#################################################
#
# Author: Johnson
# Date: 10-07-25
#
# Script to delete all unattached (orphaned) managed disks
# in Azure that are older than a specified number of days.
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
# - Correct subscription is selected



# Set your subscription (optional)
# az account set --subscription "<your-subscription-id>"



# Configuration
DAYS_OLD=7
DRY_RUN=true
LOG_FILE="orphaned_disks_$(date +%F).log"

echo "Scanning for unattached managed disks in Azure..."
echo "Dry-run mode: $DRY_RUN"
echo "Filtering disks older than $DAYS_OLD days"
echo "Logging results to $LOG_FILE"
echo "" > "$LOG_FILE"



# Get unattached managed disks
# Use az CLI and validate JSON output
disks=$(az disk list --query "[?managedBy==null]" -o json) || {
    echo "Failed to list disks. Check Azure CLI/login/subscription." >&2
    exit 1
}

# Check for valid non-empty JSON
if [ -z "$disks" ] || [ "$(echo "$disks" | jq -e 'length == 0')" = "true" ]; then
    echo "No orphaned disks found."
    exit 0
fi



# Process substitution avoids subshell issue with while loop
COUNT=0
while read -r disk; do
    NAME=$(echo "$disk" | jq -r '.name')
    RG=$(echo "$disk" | jq -r '.resourceGroup')
    CREATED=$(echo "$disk" | jq -r '.timeCreated')

    if [ -z "$CREATED" ]; then
        echo "Skipping $NAME (no creation date found)" | tee -a "$LOG_FILE"
        continue
    fi

    CREATED_DATE=$(date -d "$CREATED" +%s || true)
    NOW=$(date +%s)
    AGE_DAYS=$(( (NOW - CREATED_DATE) / 86400 ))

    if [ "$AGE_DAYS" -lt "$DAYS_OLD" ]; then
        continue
    fi

    echo "Found orphaned disk: $NAME in $RG (Age: $AGE_DAYS days)" | tee -a "$LOG_FILE"

    if [ "$DRY_RUN" = false ]; then
        echo "Deleting $NAME..."
        if az disk delete --name "$NAME" --resource-group "$RG" --yes; then
            echo "Deleted $NAME" | tee -a "$LOG_FILE"
        else
            echo "Failed to delete $NAME" | tee -a "$LOG_FILE"
        fi
    fi

    COUNT=$((COUNT + 1))
done < <(echo "$disks" | jq -c '.[]')   #Process substitution fixes count



echo ""
echo "Total orphaned disks eligible for deletion: $COUNT" | tee -a "$LOG_FILE"

if [ "$DRY_RUN" = true ]; then
    echo "Dry-run enabled. No disks were deleted." | tee -a "$LOG_FILE"
fi



################################################################################
# Script Breakdown & Explanation
#
# set -euo pipefail:
#   Enables strict error handling — fail on any command, unset var, or pipeline error.
#
# az disk list --query "[?managedBy==null]":
#   Gets all unattached managed disks.
#
# JSON empty check:
#   Safely ensures the result is valid and not just an empty string or invalid JSON.
#
# while read ... done < <(...) :
#   Uses process substitution to avoid subshell issue where COUNT would not persist.
#
# jq -r '.name', '.resourceGroup', '.timeCreated':
#   Extracts disk info for processing.
#
# DRY_RUN=true:
#   Prevents deletion; print-only mode for safety.
#
# Logging:
#   Outputs all findings to a timestamped log file for auditing.
################################################################################
