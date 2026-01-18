#!/bin/bash

# WireGuard Server Setup Script
# Ubuntu 20.04/22.04 LTS
# 
# Usage: sudo ./setup_server.sh

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m' # No Color

# Check root
if [ "$EUID" -ne 0 ]; then
  echo -e "${RED}Please run as root${NC}"
  exit 1
fi

echo -e "${GREEN}Updating system and installing WireGuard...${NC}"
apt-get update
apt-get install -y wireguard qrencode

# Generate Keys
echo -e "${GREEN}Generating keys...${NC}"
mkdir -p /etc/wireguard
chmod 700 /etc/wireguard

SERVER_PRIV_KEY=$(wg genkey)
SERVER_PUB_KEY=$(echo "$SERVER_PRIV_KEY" | wg pubkey)

# Save keys for reference (optional, but good for backup)
echo "$SERVER_PRIV_KEY" > /etc/wireguard/server_private.key
echo "$SERVER_PUB_KEY" > /etc/wireguard/server_public.key
chmod 600 /etc/wireguard/server_private.key

# Determine public IP
# Try multiple services
PUBLIC_IP=$(curl -s https://api.ipify.org || curl -s https://ifconfig.me || curl -s https://icanhazip.com)

# Validate IP (basic regex)
if [[ ! $PUBLIC_IP =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
    # Fallback to local detection if external fails or returns garbage
    PUBLIC_IP=$(ip addr | grep 'inet ' | grep -v '127.0.0.1' | awk '{print $2}' | cut -d/ -f1 | head -n 1)
fi

# Final validation
if [[ ! $PUBLIC_IP =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
    echo -e "${RED}Could not detect valid Public IP. Please check your network settings.${NC}"
    exit 1
fi

echo "$PUBLIC_IP" > /etc/wireguard/server_public_ip
echo -e "${GREEN}Detected Public IP: ${PUBLIC_IP}${NC}"

# Detect default interface
DEFAULT_IF=$(ip route list default | awk '{print $5}')

# Create Config
echo -e "${GREEN}Creating server configuration...${NC}"
cat > /etc/wireguard/wg0.conf <<EOF
[Interface]
PrivateKey = $SERVER_PRIV_KEY
Address = 10.8.0.1/24
ListenPort = 51820
MTU = 1280
SaveConfig = true
PostUp = ufw route allow in on wg0 out on $DEFAULT_IF
PostUp = iptables -t nat -A POSTROUTING -o $DEFAULT_IF -j MASQUERADE
PostDown = ufw route delete allow in on wg0 out on $DEFAULT_IF
PostDown = iptables -t nat -D POSTROUTING -o $DEFAULT_IF -j MASQUERADE
EOF

chmod 600 /etc/wireguard/wg0.conf

# Enable IP Forwarding
echo -e "${GREEN}Enabling IP forwarding...${NC}"
sed -i 's/#net.ipv4.ip_forward=1/net.ipv4.ip_forward=1/' /etc/sysctl.conf
sysctl -p

# Firewall Setup
echo -e "${GREEN}Configuring firewall (UFW)...${NC}"
if command -v ufw > /dev/null; then
    ufw allow 51820/udp
    ufw allow OpenSSH
    # Allow forwarding policy
    # We update /etc/default/ufw policy to ACCEPT for routed traffic isn't strictly necessary if we use route allow, 
    # but often recommended. However, for simplicity allowing via rules is usually enough or we rely on PostUp/PostDown.
    # We will just enable UFW if not enabled.
    if ! ufw status | grep -q "Status: active"; then
        echo -e "${GREEN}Enabling UFW...${NC}"
        # Careful not to lock out SSH, allow OpenSSH was redundant but safe
        ufw --force enable
    fi
else
    echo -e "${RED}UFW not found, assuming manual iptables management.${NC}"
fi

# Start WireGuard
echo -e "${GREEN}Starting WireGuard...${NC}"
systemctl enable wg-quick@wg0
systemctl start wg-quick@wg0

echo -e "${GREEN}WireGuard server installed and configured!${NC}"
echo -e "Server Public IP: ${PUBLIC_IP}"
echo -e "Public Key: ${SERVER_PUB_KEY}"
echo -e "\n${YELLOW}IMPORTANT CAUTION:${NC}"
echo -e "If you are running this on a cloud provider (AWS, Google Cloud, Azure, DigitalOcean, etc.),"
echo -e "you MUST also open UDP port 51820 in your provider's Firewall/Security Group settings."
echo -e "UFW rules inside the OS are often not enough!"
