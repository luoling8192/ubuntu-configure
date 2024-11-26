#!/bin/bash

# Source colors
source "$(dirname "${BASH_SOURCE[0]}")/colors.sh"

# Helper function for confirmation
confirm() {
    read -p "$(echo -e "${YELLOW}$1 [y/N]${NC} ")" response
    case "$response" in
        [yY][eE][sS]|[yY]) 
            return 0
            ;;
        *)
            return 1
            ;;
    esac
}

# Helper function for error handling
handle_error() {
    local cmd="$1"
    local error_msg="$2"
    $cmd || echo -e "${RED}${error_msg}${NC}"
}

# Helper function for running commands with zsh
run_zsh_cmd() {
    zsh -c "$1" || echo -e "${RED}Failed to run: $1${NC}"
} 
