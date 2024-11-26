#!/bin/bash

configure_static_ip() {
    if ! command -v netplan >/dev/null 2>&1; then
        echo -e "${YELLOW}Netplan is not installed, skipping static IP configuration...${NC}"
        return
    fi

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
