#!/bin/bash

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
