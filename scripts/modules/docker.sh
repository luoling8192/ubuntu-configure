#!/bin/bash

setup_docker() {
    if command -v docker >/dev/null 2>&1; then
        echo -e "${GREEN}Docker is already installed, skipping...${NC}"
        return
    fi

    if confirm "Install Docker?"; then
        echo -e "${GREEN}Installing Docker...${NC}"
        
        # Remove old Docker packages first
        for pkg in docker.io docker-doc docker-compose docker-compose-v2 podman-docker containerd runc; do
            handle_error "sudo apt-get remove -y $pkg" "Failed to remove old Docker package: $pkg"
        done

        # Install prerequisites and setup Docker repository
        handle_error "sudo apt-get update" "Failed to update package list"
        handle_error "sudo apt-get install -y ca-certificates curl" "Failed to install prerequisites"
        handle_error "sudo install -m 0755 -d /etc/apt/keyrings" "Failed to create keyrings directory"
        handle_error "sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc" "Failed to download Docker GPG key"
        handle_error "sudo chmod a+r /etc/apt/keyrings/docker.asc" "Failed to set Docker GPG key permissions"

        handle_error "echo \"deb [arch=\$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu \$(. /etc/os-release && echo \"\$VERSION_CODENAME\") stable\" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null" "Failed to add Docker repository"

        handle_error "sudo apt-get update" "Failed to update package list"
        handle_error "sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin" "Failed to install Docker"
        handle_error "sudo usermod -aG docker $USER" "Failed to add user to docker group"
        
        echo -e "${GREEN}Docker installation completed. Please log out and back in for group changes to take effect.${NC}"
    fi
}
