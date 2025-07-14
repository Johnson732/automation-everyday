#!/bin/bash

#################################################
#
# Author: Johnson
# Date: 14-07-25
#
# Script to check if a Linux service is running,
# and restart it automatically if not.
#
# Use case: Monitoring critical services like nginx
#
# Version: 1.0
#
#################################################

# Prerequisites:
# - Must be run with sudo privileges (to restart services)
# - `systemctl` must be available on the system (Systemd-based distros)

# Configuration: Set the service you want to monitor
SERVICE_NAME="nginx"

echo "Checking status of service: $SERVICE_NAME"

# Check if the service is active
if ! systemctl is-active --quiet "$SERVICE_NAME"; then
    echo "$SERVICE_NAME is not running."
    echo "Attempting to restart $SERVICE_NAME..."
    
    # Restart the service
    systemctl restart "$SERVICE_NAME"

    # Re-check status after restart attempt
    if systemctl is-active --quiet "$SERVICE_NAME"; then
        echo "$SERVICE_NAME restarted successfully."
    else
        echo "Failed to restart $SERVICE_NAME. Please check logs."
        exit 1
    fi
else
    echo "$SERVICE_NAME is running normally."
fi

################################################################################
# Script Breakdown & Explanation
#
# systemctl is-active --quiet "$SERVICE_NAME":
#   Silently checks if the service is running (returns exit code).
#
# systemctl restart "$SERVICE_NAME":
#   Restarts the service if it's not running.
#
# Re-check after restart:
#   Ensures the service actually came back up.
#
# Output:
#   Uses structured echo to make logs readable.
#
# Exit Codes:
#   0 - Success / service is already running
#   1 - Service failed to restart
################################################################################
