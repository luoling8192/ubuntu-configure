#!/bin/bash

configure_ssh() {
    echo -e "${GREEN}Configuring SSH server...${NC}"
    local config_file="/etc/ssh/sshd_config"
    
    # Fix sed commands by properly escaping quotes and using correct syntax
    handle_error "sudo sed -i 's/^#Port 22/Port 22/' $config_file" "Failed to configure SSH port"
    handle_error "sudo sed -i 's/^#PubkeyAuthentication yes/PubkeyAuthentication yes/' $config_file" "Failed to enable SSH key authentication" 
    handle_error "sudo sed -i 's/^#ClientAliveInterval 0/ClientAliveInterval 60/' $config_file" "Failed to set client alive interval"
    handle_error "sudo sed -i 's/^#ClientAliveCountMax 3/ClientAliveCountMax 3/' $config_file" "Failed to set client alive count"

    setup_ssh_keys
    restart_ssh
}

setup_ssh_keys() {
    echo -e "${GREEN}Setting up SSH keys...${NC}"
    handle_error "mkdir -p $HOME/.ssh" "Failed to create SSH directory"
    handle_error "curl -fsSL https://github.com/$GITHUB_USER.keys -o $HOME/.ssh/authorized_keys" "Failed to download SSH keys"
    handle_error "chmod 700 $HOME/.ssh" "Failed to set SSH directory permissions"
    handle_error "chmod 600 $HOME/.ssh/authorized_keys" "Failed to set SSH key permissions"
}

restart_ssh() {
    echo -e "${GREEN}Restarting SSH service...${NC}"
    # Try ssh.service first since sshd.service is not found
    if ! sudo systemctl restart ssh; then
        echo -e "${YELLOW}ssh.service not found, trying sshd.service...${NC}"
        handle_error "sudo systemctl restart sshd" "Failed to restart SSH service"
    fi
}
