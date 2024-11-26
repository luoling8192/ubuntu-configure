# 🚀 Ubuntu Configure

🛠️ A streamlined script for setting up Ubuntu development environments with modern tools and sensible defaults

## ✨ Features

### 🌐 Network Configuration
- Static IP setup with configurable search domain
- APT mirror configuration using Tsinghua mirrors

### 🔧 System Tools
- 📦 Essential build tools
- 🐚 ZSH with Zim framework and plugins
- 🎨 Powerlevel10k theme with custom configuration
- 📝 Neovim editor and modern CLI tools

### 🔑 Development Setup
- 🔒 SSH configuration with ed25519 key support
- 📝 Git with GitHub integration
- 📦 Node.js (via NVM) with pnpm
- 🐹 Go environment
- 🐋 Docker installation

## 🚀 Quick Start
1. Clone the repository:
   ```bash
   git clone https://github.com/luoling8192/ubuntu-configure.git
   cd ubuntu-configure
   ```

2. Make the script executable:
   ```bash
   chmod +x install.sh
   ```

3. Run the setup script:
   ```bash
   ./install.sh
   ```

4. Follow the interactive prompts to customize your installation.

## ⚙️ Configuration

You can customize the installation by modifying the `config.sh` file. This file contains important configuration variables such as:

- Network settings (NETPLAN_SEARCH, MIRROR)
- System packages (SYSTEM_PACKAGES, SHELL_PACKAGES, UTIL_PACKAGES) 
- Git configuration (GITHUB_USER, GITHUB_EMAIL)
- And more...
