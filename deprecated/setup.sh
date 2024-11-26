#!/bin/bash

# Define colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Define package groups
NETPLAN_FILE="/etc/netplan/00-installer-config.yaml"
NETPLAN_SEARCH="luoling.moe"
MIRROR="https://mirrors.tuna.tsinghua.edu.cn/ubuntu"
KEYRING="/usr/share/keyrings/ubuntu-archive-keyring.gpg"
SYSTEM_PACKAGES="build-essential"
SHELL_PACKAGES="zsh neovim curl wget nala"
UTIL_PACKAGES="neofetch eza htop"
ZIMRC="$HOME/.zimrc"
ZSHRC="$HOME/.zshrc"
GITHUB_USER="luoling8192"
GITHUB_EMAIL="git@luoling.moe"
P10K_CONFIG="$HOME/.p10k.zsh"

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

# Network configuration
configure_static_ip() {
    if ! command -v netplan >/dev/null 2>&1; then
        echo -e "${YELLOW}Netplan is not installed, skipping static IP configuration...${NC}"
        return
    }

    echo -e "${GREEN}Configuring static IP...${NC}"
    
    # Get current network interface
    interface=$(ip route | grep default | awk '{print $5}')
    echo -e "${GREEN}Current network interface: ${interface}${NC}"
    
    # Get current IP address
    current_ip=$(ip -4 addr show $interface | grep -oP '(?<=inet\s)\d+(\.\d+){3}/\d+')
    echo -e "${GREEN}Current IP address: ${current_ip}${NC}"
    
    # Get current gateway
    current_gateway=$(ip route | grep default | awk '{print $3}')
    echo -e "${GREEN}Current gateway: ${current_gateway}${NC}"
    
    # Get current nameservers
    current_nameservers=$(grep nameserver /etc/resolv.conf | awk '{print $2}' | tr '\n' ' ')
    echo -e "${GREEN}Current nameservers: ${current_nameservers}${NC}"

    while true; do
        read -p "$(echo -e "${YELLOW}Enter network interface name [${interface}]:${NC} ")" input_interface
        interface=${input_interface:-$interface}
        
        read -p "$(echo -e "${YELLOW}Enter IP address [${current_ip}]:${NC} ")" input_ip
        ip_address=${input_ip:-$current_ip}
        
        read -p "$(echo -e "${YELLOW}Enter gateway address [${current_gateway}]:${NC} ")" input_gateway
        gateway=${input_gateway:-$current_gateway}
        
        read -p "$(echo -e "${YELLOW}Enter nameservers [${current_nameservers}]:${NC} ")" input_nameservers
        nameservers=${input_nameservers:-$current_nameservers}

        # Get MAC address of the interface
        mac_address=$(ip link show $interface | grep -oP '(?<=ether\s)\S+')

        # Create temporary file first to avoid tee errors with IP addresses
        config_content="network:
  version: 2
  ethernets:
    $interface:
      match:
        macaddress: \"$mac_address\"
      addresses:
        - $ip_address
      nameservers:
        addresses: [$nameservers]
        search:
          - $NETPLAN_SEARCH
      dhcp6: true
      set-name: \"$interface\"
      routes:
        - to: \"default\"
          via: \"$gateway\""

        echo "$config_content" > /tmp/netplan-config
        echo "$config_content"
        
        echo -e "${YELLOW}Review the configuration above. Apply this configuration? [A]pply/[R]eenter/[C]ancel${NC}"
        read -r action
        case "$action" in
            [Aa])
                handle_error "sudo mv /tmp/netplan-config $NETPLAN_FILE" "Failed to create netplan config"
                handle_error "sudo chmod 600 $NETPLAN_FILE" "Failed to set netplan config permissions"
                handle_error "sudo netplan apply" "Failed to apply netplan config"
                handle_error "ip -c a" "Failed to show network interfaces"
                echo -e "${GREEN}Static IP configuration completed${NC}"
                return
                ;;
            [Rr])
                echo -e "${YELLOW}Re-entering configuration...${NC}"
                continue
                ;;
            *)
                echo -e "${YELLOW}Configuration cancelled.${NC}"
                return
                ;;
        esac
    done
}

# Package management
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

# Git configuration
setup_git() {
    echo -e "${GREEN}Setting up Git...${NC}"
    handle_error "git config --global user.name \"$GITHUB_USER\"" "Failed to set Git username"
    handle_error "git config --global user.email \"$GITHUB_EMAIL\"" "Failed to set Git email"
}

# SSH configuration
configure_ssh() {
    echo -e "${GREEN}Configuring SSH server...${NC}"
    local config_file="/etc/ssh/sshd_config"
    
    handle_error "sudo sed -i 's/#Port 22/Port 22/' $config_file" "Failed to configure SSH port"
    handle_error "sudo sed -i 's/#PubkeyAuthentication yes/PubkeyAuthentication yes/' $config_file" "Failed to enable SSH key authentication"
    handle_error "sudo sed -i 's/#ClientAliveInterval 0/ClientAliveInterval 60/' $config_file" "Failed to set client alive interval"
    handle_error "sudo sed -i 's/#ClientAliveCountMax 3/ClientAliveCountMax 3/' $config_file" "Failed to set client alive count"

    setup_ssh_keys
    restart_ssh
}

setup_ssh_keys() {
    echo -e "${GREEN}Setting up SSH keys...${NC}"
    handle_error "mkdir -p ~/.ssh" "Failed to create SSH directory"
    handle_error "curl -fsSL https://github.com/$GITHUB_USER.keys > ~/.ssh/authorized_keys" "Failed to download SSH keys"
    handle_error "chmod 700 ~/.ssh" "Failed to set SSH directory permissions"
    handle_error "chmod 600 ~/.ssh/authorized_keys" "Failed to set SSH key permissions"
}

restart_ssh() {
    echo -e "${GREEN}Restarting SSH service...${NC}"
    handle_error "sudo systemctl restart sshd" "Failed to restart SSH service"
}

# Shell configuration
setup_zsh() {
    change_default_shell
    install_zim
    install_zim_plugins
    configure_shell_aliases
    install_atuin
    setup_env_vars
    add_command_not_found_handler
    configure_p10k
    setup_zsh_completion
}

change_default_shell() {
    echo -e "${GREEN}Changing default shell to zsh...${NC}"
    handle_error "sudo chsh -s $(which zsh)" "Failed to change default shell"
    handle_error "rm -rf ~/.zim" "Failed to remove existing Zim installation"
    
    if confirm "Remove existing zshrc?"; then
        handle_error "rm -f $ZSHRC" "Failed to remove existing zshrc"
    fi
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
    
    if confirm "Do you want to install powerlevel10k theme?"; then
        plugins+=("romkatv/powerlevel10k --use degit")
        
        if confirm "Do you want to apply powerlevel10k configuration?"; then
            echo -e "${GREEN}Configuring Powerlevel10k theme...${NC}"
            handle_error "cp .p10k.zsh ~/.p10k.zsh" "Failed to copy .p10k.zsh"
        fi
    fi
    
    for plugin in "${plugins[@]}"; do
        handle_error "echo \"zmodule $plugin\" >> $ZIMRC" "Failed to add plugin: $plugin"
    done
    
    run_zsh_cmd "zimfw install"
    source $ZSHRC
}

configure_shell_aliases() {
    echo -e "${GREEN}Configuring shell aliases...${NC}"
    handle_error "cat << 'EOF' >> $ZSHRC
# Aliases
alias vim=nvim
alias ls=eza
alias ll=\"eza -lah\"
alias sudo=\"sudo \"
alias ip=\"ip -c\"
alias reload=\"source \$HOME/.zshrc\"
alias zshrc=\"vim \$HOME/.zshrc\"

# Git aliases
alias gcl=\"git clone\"
alias ga=\"git add\"
alias gaa=\"git add -A\"
alias gcm=\"git commit -m\"
alias gcma=\"git commit -m -a\"
alias gp=\"git push\"
alias gpl=\"git pull --rebase\"
alias main=\"git switch main\"
EOF" "Failed to configure shell aliases"
    source $ZSHRC
}

install_atuin() {
    echo -e "${GREEN}Installing Atuin shell history manager...${NC}"
    if command -v atuin >/dev/null 2>&1; then
        echo -e "${YELLOW}Atuin is already installed, skipping...${NC}"
        return
    fi

    if confirm "Do you want to install Atuin shell history manager?"; then
        handle_error "bash <(curl -fsSL \"https://raw.githubusercontent.com/atuinsh/atuin/main/install.sh\")" "Failed to install Atuin"
        handle_error "echo 'eval \"\$(atuin init zsh)\"' >> $ZSHRC" "Failed to configure Atuin"
        source $ZSHRC

        if confirm "Do you want to import existing shell history?"; then
            run_zsh_cmd "atuin import auto"
        fi
    fi
}

setup_env_vars() {
    echo -e "${GREEN}Setting up environment variables...${NC}"
    handle_error "echo 'export EDITOR=\"nvim\"' >> $ZSHRC" "Failed to set editor"
    handle_error "echo 'export HISTORY_IGNORE=\"(jetbrains*)\"' >> $ZSHRC" "Failed to set history ignore"
    source $ZSHRC
}

add_command_not_found_handler() {
    echo -e "${GREEN}Adding command not found handler...${NC}"
    handle_error "cat << 'EOF' >> $ZSHRC
# Handle command not found by removing from history
[ \${BASH_VERSION} ] && PROMPT_COMMAND=\"mypromptcommand\"
[ \${ZSH_VERSION} ] && precmd() { mypromptcommand; }
function mypromptcommand {
    local exit_status=\$?
    if [ \${ZSH_VERSION} ]; then
        local number=\$(history -1 | awk '{print \$1}')
    elif [ \${BASH_VERSION} ]; then
        local number=\$(history 1 | awk '{print \$1}')
    fi
    if [ -n \"\$number\" ]; then
        if [ \$exit_status -eq 127 ] && ([ -z \$HISTLASTENTRY ] || [ \$HISTLASTENTRY -lt \$number ]); then
            local RED='\033[0;31m'
            local NC='\033[0m'
            if [ \${ZSH_VERSION} ]; then
                local HISTORY_IGNORE=\"\${(b)\$(fc -ln \$number \$number)}\"
                fc -W
                fc -p \$HISTFILE \$HISTSIZE \$SAVEHIST
            elif [ \${BASH_VERSION} ]; then
                local HISTORY_IGNORE=\$(history 1 | awk '{print \$2}')
                history -d \$number
            fi
            echo -e \"\${RED}Deleted '\$HISTORY_IGNORE' from history.\${NC}\"
        else
            HISTLASTENTRY=\$number
        fi
    fi
}
EOF" "Failed to add command not found handler"
    source $ZSHRC
}

# Node.js environment
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

# Go environment
setup_go() {
    if command -v go >/dev/null 2>&1; then
        echo -e "${GREEN}Go is already installed, skipping...${NC}"
        return
    fi

    install_go
    configure_go_env
    create_go_workspace
    verify_go
}

install_go() {
    echo -e "${GREEN}Downloading and installing Go...${NC}"
    GO_VERSION="1.21.5"
    GO_TAR="go${GO_VERSION}.linux-amd64.tar.gz"
    
    handle_error "wget \"https://go.dev/dl/${GO_TAR}\"" "Failed to download Go"
    handle_error "sudo rm -rf /usr/local/go" "Failed to remove old Go installation"
    handle_error "sudo tar -C /usr/local -xzf ${GO_TAR}" "Failed to extract Go"
    handle_error "rm ${GO_TAR}" "Failed to cleanup Go installer"
}

configure_go_env() {
    echo -e "${GREEN}Configuring Go environment...${NC}"
    handle_error "cat << 'EOF' >> $ZSHRC
# Go configuration
export GOROOT=/usr/local/go
export GOPATH=\$HOME/go
export PATH=\$PATH:\$GOROOT/bin:\$GOPATH/bin
EOF" "Failed to configure Go environment"

    export GOROOT=/usr/local/go
    export GOPATH=$HOME/go
    export PATH=$PATH:$GOROOT/bin:$GOPATH/bin
}

create_go_workspace() {
    echo -e "${GREEN}Creating Go workspace...${NC}"
    handle_error "mkdir -p $GOPATH/{bin,src,pkg}" "Failed to create Go workspace"
}

verify_go() {
    echo -e "${GREEN}Verifying Go installation...${NC}"
    run_zsh_cmd "go version"
}

# Docker environment
setup_docker() {
    if command -v docker >/dev/null 2>&1; then
        echo -e "${GREEN}Docker is already installed, skipping...${NC}"
        return
    fi

    if confirm "Install Docker?"; then
        echo -e "${GREEN}Installing Docker...${NC}"
        handle_error "sudo install -m 0755 -d /etc/apt/keyrings" "Failed to create keyrings directory"
        handle_error "curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg" "Failed to download Docker GPG key"
        handle_error "sudo chmod a+r /etc/apt/keyrings/docker.gpg" "Failed to set Docker GPG key permissions"

        handle_error "echo \"deb [arch=\$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \$(. /etc/os-release && echo \"\$VERSION_CODENAME\") stable\" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null" "Failed to add Docker repository"

        handle_error "sudo apt update" "Failed to update package list"
        handle_error "sudo apt install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin" "Failed to install Docker"
        handle_error "sudo usermod -aG docker $USER" "Failed to add user to docker group"
        
        echo -e "${GREEN}Docker installation completed. Please log out and back in for group changes to take effect.${NC}"
    fi
}

# ZSH completion
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
    echo -e "${YELLOW}Note: After restart, check for 'compinit being called at' messages${NC}"
    echo -e "${YELLOW}and remove any duplicate compinit calls from the mentioned files.${NC}"
}

# Main execution
echo -e "${GREEN}Starting system configuration...${NC}"

if confirm "Configure static IP?"; then
    configure_static_ip
fi
if confirm "Configure APT sources?"; then
    configure_apt
fi
if confirm "Update system and install packages?"; then
    update_system
fi
if confirm "Configure SSH?"; then
    configure_ssh
fi
if confirm "Setup ZSH?"; then
    setup_zsh
fi
if confirm "Setup Node.js?"; then
    setup_node
fi
if confirm "Setup Go?"; then
    setup_go
fi
if confirm "Setup Docker?"; then
    setup_docker
fi

handle_error "neofetch" "Failed to display system information"

echo -e "${GREEN}System configuration completed!${NC}"
