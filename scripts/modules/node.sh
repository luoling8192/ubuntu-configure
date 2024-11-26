#!/bin/bash

setup_node() {
    install_nvm
    configure_nvm
    install_node
    setup_package_managers
    verify_node
}

install_nvm() {
    if [ -d "$HOME/.nvm" ]; then
        echo -e "${GREEN}NVM is already installed, skipping...${NC}"
        return
    fi

    echo -e "${GREEN}Installing Node Version Manager (nvm)...${NC}"
    handle_error "curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.7/install.sh | bash" "Failed to install NVM"
}

configure_nvm() {
    echo -e "${GREEN}Configuring nvm environment...${NC}"
    handle_error "cat << 'EOF' >> $ZSHRC
# NVM configuration
export NVM_DIR=\"\$HOME/.nvm\"
[ -s \"\$NVM_DIR/nvm.sh\" ] && \\. \"\$NVM_DIR/nvm.sh\"
[ -s \"\$NVM_DIR/bash_completion\" ] && \\. \"\$NVM_DIR/bash_completion\"
EOF" "Failed to configure NVM environment"
}

install_node() {
    if command -v node >/dev/null 2>&1; then
        echo -e "${GREEN}Node.js is already installed, skipping...${NC}"
        return
    fi

    echo -e "${GREEN}Installing latest LTS version of Node.js...${NC}"
    export NVM_DIR="$HOME/.nvm"
    [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
    run_zsh_cmd "nvm install --lts"
    run_zsh_cmd "nvm use --lts"
}

setup_package_managers() {
    if command -v pnpm >/dev/null 2>&1; then
        echo -e "${GREEN}Package managers already setup, skipping...${NC}"
        return
    fi

    echo -e "${GREEN}Setting up package managers...${NC}"
    run_zsh_cmd "corepack enable"
    run_zsh_cmd "pnpm setup"
}

verify_node() {
    echo -e "${GREEN}Verifying Node.js installation...${NC}"
    run_zsh_cmd "node --version"
    run_zsh_cmd "npm --version"
    run_zsh_cmd "pnpm --version"
} 
