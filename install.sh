#!/bin/bash

# Get the directory where the script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Check if running as root
if [ "$EUID" -eq 0 ]; then 
    echo "Please do not run as root"
    exit 1
fi

# Check Ubuntu version
if ! grep -q "Ubuntu" /etc/os-release; then
    echo "This script is only for Ubuntu"
    exit 1
fi

# Check if scripts directory exists
if [ ! -d "$SCRIPT_DIR/scripts" ]; then
    echo "Scripts directory not found"
    exit 1
fi

# Execute the main setup script
bash "$SCRIPT_DIR/scripts/setup.sh" 
