#!/bin/bash

setup_git() {
    echo -e "${GREEN}Setting up Git...${NC}"
    handle_error "git config --global user.name \"$GITHUB_USER\"" "Failed to set Git username"
    handle_error "git config --global user.email \"$GITHUB_EMAIL\"" "Failed to set Git email"
} 
