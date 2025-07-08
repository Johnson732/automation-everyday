#!/bin/bash


#################################################
#
# Author: Johnson
# Date: 08-07-25
#
# Script to shutdown all Azure VMs tagged with Environment=Dev
#
# Version: 1.0
#
#################################################



# Prerequisites:
# - Azure CLI installed
# - Logged in via `az login`
# - Right subscription is selected

# Set your subscription (optional)
# az account set --subscription "<your-subscription-id>"

echo "Fetching VMs tagged with Environment=Dev..."

# Get list of VM resource IDs with the tag Environment=Dev
vm_ids=$(az resource list \
    --resource-type "Microsoft.Compute/virtualMachines" \
    --tag Environment=Dev \
    --query "[].id" -o tsv)

if [ -z "$vm_ids" ]; then
    echo "No VMs found with tag Environment=Dev."
    exit 0
fi

echo "Shutting down the following VMs:"
for vm_id in $vm_ids; do
    echo "$vm_id"
    az vm deallocate --ids "$vm_id" --no-wait
done

echo "Shutdown command issued for all Dev VMs."



################################################################################
# 📘 Script Breakdown & Explanation
#
# az account set --subscription:
#   (Optional) Sets the active subscription for az CLI commands.
#
# az resource list:
#   Lists Azure resources.
#   --resource-type "Microsoft.Compute/virtualMachines":
#     Filters the result to only VMs.
#   --tag Environment=Dev:
#     Filters VMs that have the tag key=value pair.
#   --query "[].id":
#     Extracts only the VM IDs.
#   -o tsv:
#     Outputs in tab-separated format (plain text).
#
# if [ -z "$vm_ids" ]; then ...:
#   Checks if no VMs matched the filter. Exits early if true.
#
# for vm_id in $vm_ids; do:
#   Iterates through each VM ID returned by the query.
#
# az vm deallocate --ids "$vm_id" --no-wait:
#   Deallocates the VM (stops it, releases resources but keeps disk).
#   --no-wait:
#     Sends the shutdown request asynchronously.
################################################################################
