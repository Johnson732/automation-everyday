#!/bin/bash

#################################################
#
# Author: Johnson
# Date: 09-07-25
#
# Script to delete old untagged images from Azure Container Registry
#
# Version: 1.0
#
#################################################


# Prerequisites:
# - Azure CLI installed
# - Logged in via `az login`
# - ACR name and repository known
# - `acr purge` extension installed: `az extension add --name acr`
#   (If not available, use REST API via curl/Python)

# Set variables
ACR_NAME="yourACRName"         # Replace with your ACR name (without .azurecr.io)
REPO_NAME="your-repository"    # Replace with your image repo name
DAYS_OLD=7                     # Delete images older than 7 days
DRY_RUN=true                   # Change to false to actually delete

echo "Starting ACR image cleanup for '$ACR_NAME/$REPO_NAME'..."

# Ensure acr CLI extension is installed
if ! az extension show --name acr &> /dev/null; then
    echo "Installing 'acr' CLI extension..."
    az extension add --name acr
fi

# Execute purge
az acr run --registry "$ACR_NAME" \
    --cmd "acr purge --repository $REPO_NAME --filter 'untagged<${DAYS_OLD}d' --untagged --ago ${DAYS_OLD}d ${DRY_RUN:+--dry-run}" \
    /dev/null

echo "ACR cleanup completed for repository: $REPO_NAME"

################################################################################
# 📘 Script Breakdown & Explanation
#
# ACR_NAME / REPO_NAME:
#   Specify your container registry and the image repo you want to clean.
#
# az acr purge:
#   Command to remove old and untagged images.
#
# --filter 'untagged<7d':
#   Deletes untagged images older than 7 days.
#
# --dry-run:
#   Simulates deletion. Remove this flag to actually delete.
#
# az acr run:
#   Runs purge as a remote command on ACR (since purge runs in ACR tasks).
#
# Notes:
# - Only untagged images are deleted here.
# - To clean up tagged images based on policy, more advanced logic is needed.
################################################################################
