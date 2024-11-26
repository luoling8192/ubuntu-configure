#!/bin/bash

configure_ssh() {
    echo -e "${GREEN}Configuring SSH server...${NC}"
    
    if confirm "Configure SSH server settings?"; then
        local config_file="/etc/ssh/sshd_config"
        
        # Use double quotes to avoid sed expression errors
        echo 'Port 22' | sudo tee -a $config_file > /dev/null
        echo 'PubkeyAuthentication yes' | sudo tee -a $config_file > /dev/null
        echo 'ClientAliveInterval 60' | sudo tee -a $config_file > /dev/null
        echo 'ClientAliveCountMax 3' | sudo tee -a $config_file > /dev/null
    fi

    if confirm "Set up SSH keys?"; then
        setup_ssh_keys
    fi

    if confirm "Configure GitHub SSH access?"; then
        setup_github_ssh
    fi

    if confirm "Restart SSH service?"; then
        restart_ssh
    fi
}

setup_ssh_keys() {
    echo -e "${GREEN}Setting up SSH keys...${NC}"
    
    if confirm "Create SSH directory and download authorized keys?"; then
        handle_error "mkdir -p $HOME/.ssh" "Failed to create SSH directory"
        handle_error "curl -fsSL https://github.com/$GITHUB_USER.keys -o $HOME/.ssh/authorized_keys" "Failed to download SSH keys"
        handle_error "chmod 700 $HOME/.ssh" "Failed to set SSH directory permissions"
        handle_error "chmod 600 $HOME/.ssh/authorized_keys" "Failed to set SSH key permissions"
    fi

    # Ask if user wants to generate new ed25519 key
    if confirm "Generate new ed25519 SSH key?"; then
        local commit_msg
        read -p "Enter commit message for the key (default: hostname): " commit_msg
        # Use hostname if no commit message provided
        commit_msg=${commit_msg:-$(hostname)}
        
        # Generate ed25519 key with commit message as comment
        handle_error "ssh-keygen -t ed25519 -C $commit_msg" "Failed to generate ed25519 key"
        
        # Print the public key
        echo -e "\n${GREEN}Your new public key:${NC}"
        cat "$HOME/.ssh/id_ed25519.pub"
    fi
}

setup_github_ssh() {
    echo -e "${GREEN}Setting up GitHub SSH config...${NC}"
    local ssh_config="$HOME/.ssh/config"
    local github_config="Host github.com
    HostName ssh.github.com
    User git
    Port 443"
    
    if confirm "Configure GitHub SSH access over HTTPS port 443?"; then
        if [ ! -f "$ssh_config" ] || ! grep -q "Host github.com" "$ssh_config"; then
            # Add newline before config if file exists
            [ -f "$ssh_config" ] && echo "" >> "$ssh_config"
            echo "$github_config" >> "$ssh_config"
        fi

        handle_error "chmod 600 $ssh_config" "Failed to set SSH config permissions"
    fi
}

restart_ssh() {
    echo -e "${GREEN}Restarting SSH service...${NC}"
    # Try ssh.service first since sshd.service is not found
    if ! sudo systemctl restart ssh; then
        echo -e "${YELLOW}ssh.service not found, trying sshd.service...${NC}"
        handle_error "sudo systemctl restart sshd" "Failed to restart SSH service"
    fi
}
