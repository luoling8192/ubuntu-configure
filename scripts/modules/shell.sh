#!/bin/bash

setup_zsh() {
    if [ ! -f "/bin/zsh" ]; then
        echo -e "${RED}ZSH is not installed. Please run system update first.${NC}"
        return 1
    fi

    install_zim
    install_zim_plugins
    setup_zsh_completion
    setup_p10k
}

install_zim() {
    reset
    echo -e "${GREEN}Installing Zim framework...${NC}"
    handle_error "curl -fsSL https://raw.githubusercontent.com/zimfw/install/master/install.zsh | zsh" "Failed to install Zim framework"
    source $ZSHRC
}

install_zim_plugins() {
    reset
    echo -e "${GREEN}Installing Zim plugins...${NC}"
    local plugins=(
        "kiesman99/zim-zoxide"
        "Aloxaf/fzf-tab"
    )
    
    for plugin in "${plugins[@]}"; do
        handle_error "echo \"zmodule $plugin\" >> $ZIMRC" "Failed to add plugin: $plugin"
    done
    
    run_zsh_cmd "zimfw install"
    source $ZSHRC
}

setup_zsh_completion() {
    echo -e "${GREEN}Setting up ZSH completion...${NC}"
    
    if ! grep -q "skip_global_compinit=1" ~/.zshenv 2>/dev/null; then
        handle_error "echo \"skip_global_compinit=1\" >> ~/.zshenv" "Failed to add skip_global_compinit to .zshenv"
    fi

    handle_error "cat > ~/.zshenv.debug <<\\EOF
autoload -Uz +X compinit
functions[compinit]=\$'print -u2 \\'compinit being called at \\'\${funcfiletrace[1]}
'\${functions[compinit]}
EOF" "Failed to create debug file"

    if [ -f ~/.zshenv ]; then
        handle_error "cp ~/.zshenv ~/.zshenv.bak" "Failed to backup .zshenv"
    fi

    handle_error "cat ~/.zshenv.debug >> ~/.zshenv" "Failed to update .zshenv"
    handle_error "rm ~/.zshenv.debug" "Failed to cleanup debug file"

    echo -e "${GREEN}ZSH completion setup completed. Please restart your terminal to apply changes.${NC}"
}
