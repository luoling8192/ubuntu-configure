#!/bin/bash

# Get the directory where the script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Source required files
source "$SCRIPT_DIR/utils/colors.sh"
source "$SCRIPT_DIR/utils/helpers.sh"
source "$SCRIPT_DIR/config.sh"

# Source all modules
for module in "$SCRIPT_DIR/modules"/*.sh; do
    source "$module"
done

# Main execution
echo -e "${GREEN}Starting system configuration...${NC}"

PS3="Please select an option (1-11): "
options=(
    "Run all steps"
    "Configure static IP"
    "Configure APT sources"
    "Update system and install packages"
    "Configure SSH"
    "Setup ZSH"
    "Setup Git"
    "Setup Node.js"
    "Setup Go"
    "Setup Docker"
    "Exit"
)

while true; do
    echo -e "\n${GREEN}Available configuration options:${NC}"
    select opt in "${options[@]}"; do
        case $REPLY in
            1) 
                echo -e "${GREEN}Running all configuration steps...${NC}"
                for i in {2..10}; do
                    echo -e "\n${GREEN}Step $((i-1)): ${options[$i-1]}${NC}"
                    case $i in
                        2) echo -e "${YELLOW}This will configure a static IP address for your network interface${NC}" ;;
                        3) echo -e "${YELLOW}This will set up APT package sources using Tsinghua mirrors${NC}" ;;
                        4) echo -e "${YELLOW}This will update system packages and install required tools${NC}" ;;
                        5) echo -e "${YELLOW}This will configure SSH server and set up SSH keys from GitHub${NC}" ;;
                        6) echo -e "${YELLOW}This will install and configure ZSH with Zim framework and plugins${NC}" ;;
                        7) echo -e "${YELLOW}This will configure Git with your GitHub credentials${NC}" ;;
                        8) echo -e "${YELLOW}This will install Node.js via NVM and set up package managers${NC}" ;;
                        9) echo -e "${YELLOW}This will install Go and configure the workspace${NC}" ;;
                        10) echo -e "${YELLOW}This will install Docker and add you to the docker group${NC}" ;;
                    esac
                    read -p "Run this step? [Y/n] " response
                    response=${response:-Y}
                    if [[ $response =~ ^[Yy]$ ]]; then
                        case $i in
                            2) configure_static_ip && echo -e "${GREEN}Static IP configuration completed successfully${NC}" ;;
                            3) configure_apt && echo -e "${GREEN}APT sources configured successfully${NC}" ;;
                            4) update_system && echo -e "${GREEN}System update completed successfully${NC}" ;;
                            5) configure_ssh && echo -e "${GREEN}SSH configuration completed successfully${NC}" ;;
                            6) setup_zsh && echo -e "${GREEN}ZSH setup completed successfully${NC}" ;;
                            7) setup_git && echo -e "${GREEN}Git configuration completed successfully${NC}" ;;
                            8) setup_node && echo -e "${GREEN}Node.js setup completed successfully${NC}" ;;
                            9) setup_go && echo -e "${GREEN}Go setup completed successfully${NC}" ;;
                            10) setup_docker && echo -e "${GREEN}Docker setup completed successfully${NC}" ;;
                        esac
                    fi
                done
                break ;;
            2) 
                echo -e "${YELLOW}This will configure a static IP address for your network interface${NC}"
                confirm "Continue?" && configure_static_ip && echo -e "${GREEN}Static IP configuration completed successfully${NC}"
                break ;;
            3)
                echo -e "${YELLOW}This will set up APT package sources using Tsinghua mirrors${NC}"
                confirm "Continue?" && configure_apt && echo -e "${GREEN}APT sources configured successfully${NC}"
                break ;;
            4)
                echo -e "${YELLOW}This will update system packages and install required tools${NC}"
                confirm "Continue?" && update_system && echo -e "${GREEN}System update completed successfully${NC}"
                break ;;
            5)
                echo -e "${YELLOW}This will configure SSH server and set up SSH keys from GitHub${NC}"
                confirm "Continue?" && configure_ssh && echo -e "${GREEN}SSH configuration completed successfully${NC}"
                break ;;
            6)
                echo -e "${YELLOW}This will install and configure ZSH with Zim framework and plugins${NC}"
                confirm "Continue?" && setup_zsh && echo -e "${GREEN}ZSH setup completed successfully${NC}"
                break ;;
            7)
                echo -e "${YELLOW}This will configure Git with your GitHub credentials${NC}"
                confirm "Continue?" && setup_git && echo -e "${GREEN}Git configuration completed successfully${NC}"
                break ;;
            8)
                echo -e "${YELLOW}This will install Node.js via NVM and set up package managers${NC}"
                confirm "Continue?" && setup_node && echo -e "${GREEN}Node.js setup completed successfully${NC}"
                break ;;
            9)
                echo -e "${YELLOW}This will install Go and configure the workspace${NC}"
                confirm "Continue?" && setup_go && echo -e "${GREEN}Go setup completed successfully${NC}"
                break ;;
            10)
                echo -e "${YELLOW}This will install Docker and add you to the docker group${NC}"
                confirm "Continue?" && setup_docker && echo -e "${GREEN}Docker setup completed successfully${NC}"
                break ;;
            11) echo -e "${GREEN}Exiting...${NC}"; exit 0 ;;
            *) echo -e "${RED}Invalid option${NC}" ;;
        esac
    done
done

handle_error "neofetch" "Failed to display system information"

echo -e "${GREEN}System configuration completed!${NC}"
