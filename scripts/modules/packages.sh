#!/bin/bash

configure_apt() {
    echo -e "${GREEN}Configuring APT sources...${NC}"
    handle_error "sudo tee /etc/apt/sources.list.d/ubuntu.sources << EOF
Types: deb
URIs: $MIRROR
Suites: noble noble-updates noble-backports
Components: main restricted universe multiverse
Signed-By: $KEYRING

Types: deb-src
URIs: $MIRROR
Suites: noble noble-updates noble-backports
Components: main restricted universe multiverse
Signed-By: $KEYRING

Types: deb
URIs: http://security.ubuntu.com/ubuntu/
Suites: noble-security
Components: main restricted universe multiverse
Signed-By: $KEYRING

Types: deb-src
URIs: http://security.ubuntu.com/ubuntu/
Suites: noble-security
Components: main restricted universe multiverse
Signed-By: $KEYRING
EOF" "Failed to configure APT sources"
}

update_system() {
    echo -e "${GREEN}Updating system packages...${NC}"
    handle_error "sudo apt update -y && sudo apt upgrade -y" "Failed to update system packages"
    echo -e "${GREEN}Installing required packages...${NC}"
    handle_error "sudo apt install -y $SYSTEM_PACKAGES $SHELL_PACKAGES $UTIL_PACKAGES" "Failed to install required packages"
} 
