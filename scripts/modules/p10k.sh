#!/bin/bash

setup_p10k() {
    install_p10k
    configure_p10k
}

install_p10k() {
    if grep -q "romkatv/powerlevel10k" "$ZIMRC" 2>/dev/null; then
        echo -e "${YELLOW}Powerlevel10k is already installed, skipping...${NC}"
        return
    fi

    echo -e "${GREEN}Installing Powerlevel10k...${NC}"
    handle_error "echo 'zmodule romkatv/powerlevel10k --use degit' >> $ZIMRC" "Failed to add Powerlevel10k to zimrc"
    run_zsh_cmd "zimfw install"
}

configure_p10k() {
    if [ -f "$P10K_CONFIG" ]; then
        echo -e "${YELLOW}Powerlevel10k configuration already exists, skipping...${NC}"
        return
    fi

    if confirm "Configure Powerlevel10k?"; then
        # First try to copy the default configuration
        if [ -f "$SCRIPT_DIR/assets/.p10k.zsh" ]; then
            echo -e "${GREEN}Applying default Powerlevel10k configuration...${NC}"
            handle_error "cp $SCRIPT_DIR/assets/.p10k.zsh $P10K_CONFIG" "Failed to copy .p10k.zsh"
        else
            # If no default config exists, run the configuration wizard
            echo -e "${GREEN}Running Powerlevel10k configuration wizard...${NC}"
            run_zsh_cmd "p10k configure"
        fi
    fi
} 
