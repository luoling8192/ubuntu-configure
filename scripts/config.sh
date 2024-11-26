#!/bin/bash

# Network configuration
NETPLAN_FILE="/etc/netplan/00-installer-config.yaml"
NETPLAN_SEARCH="luoling.moe"

# Package management
MIRROR="https://mirrors.tuna.tsinghua.edu.cn/ubuntu"
KEYRING="/usr/share/keyrings/ubuntu-archive-keyring.gpg"
SYSTEM_PACKAGES="build-essential"
SHELL_PACKAGES="zsh neovim curl wget nala"
UTIL_PACKAGES="neofetch eza htop"

# Shell configuration
ZIMRC="$HOME/.zimrc"
ZSHRC="$HOME/.zshrc"
P10K_CONFIG="$HOME/.p10k.zsh"

# Git configuration
GITHUB_USER="luoling8192"
GITHUB_EMAIL="git@luoling.moe" 
