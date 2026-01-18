#!/bin/bash

# WireGuard Client Setup Script
# Usage: sudo ./add_client.sh <client_name>

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m'

# Check root
if [ "$EUID" -ne 0 ]; then
  echo -e "${RED}Please run as root${NC}"
  exit 1
fi

if [ -z "$1" ]; then
    echo -e "${RED}Usage: $0 <client_name>${NC}"
    exit 1
fi

CLIENT_NAME=$1
WG_CONF="/etc/wireguard/wg0.conf"

if [ ! -f "$WG_CONF" ]; then
    echo -e "${RED}Server configuration not found at $WG_CONF. Please run setup_server.sh first.${NC}"
    exit 1
fi

echo -e "${GREEN}Generating keys for client '$CLIENT_NAME'...${NC}"
CLIENT_PRIV_KEY=$(wg genkey)
CLIENT_PUB_KEY=$(echo "$CLIENT_PRIV_KEY" | wg pubkey)
CLIENT_PSK=$(wg genpsk)
SERVER_PUB_KEY=$(cat /etc/wireguard/server_public.key)

# Determine Server Endpoint IP
if [ -f /etc/wireguard/server_public_ip ]; then
    ENDPOINT_IP=$(cat /etc/wireguard/server_public_ip)
else
    # Try multiple services if file doesn't exist
    ENDPOINT_IP=$(curl -s https://api.ipify.org || curl -s https://ifconfig.me || curl -s https://icanhazip.com)
    
    if [[ ! $ENDPOINT_IP =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
         ENDPOINT_IP=$(ip addr | grep 'inet ' | grep -v '127.0.0.1' | awk '{print $2}' | cut -d/ -f1 | head -n 1)
    fi
fi

if [[ ! $ENDPOINT_IP =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
    echo -e "${RED}Could not detect valid Server IP for Endpoint.${NC}"
    exit 1
fi

# Find available IP
# Assuming 10.8.0.0/24 subnet
OCTET=2
while grep -q "10.8.0.$OCTET" "$WG_CONF"; do
    ((OCTET++))
    if [ "$OCTET" -gt 254 ]; then
        echo -e "${RED}No available IPs in 10.8.0.0/24 subnet.${NC}"
        exit 1
    fi
done
CLIENT_IP="10.8.0.$OCTET/32"

echo -e "${GREEN}Assigning IP: $CLIENT_IP${NC}"

# Create Client Config
cat > "${CLIENT_NAME}.conf" <<EOF
[Interface]
PrivateKey = $CLIENT_PRIV_KEY
Address = 10.8.0.$OCTET/24
DNS = 8.8.8.8
MTU = 1280

[Peer]
PublicKey = $SERVER_PUB_KEY
PresharedKey = $CLIENT_PSK
Endpoint = $ENDPOINT_IP:51820
AllowedIPs = 0.0.0.0/0
PersistentKeepalive = 25
EOF

chmod 600 "${CLIENT_NAME}.conf"

# Add Peer to Server Config
echo -e "${GREEN}Adding peer to server configuration...${NC}"
cat >> "$WG_CONF" <<EOF

# Client: $CLIENT_NAME
[Peer]
PublicKey = $CLIENT_PUB_KEY
PresharedKey = $CLIENT_PSK
AllowedIPs = $CLIENT_IP
EOF

# Reload Server
echo -e "${GREEN}Reloading WireGuard server...${NC}"
wg syncconf wg0 <(wg-quick strip wg0)

echo -e "${GREEN}Client '$CLIENT_NAME' added successfully!${NC}"
echo -e "Configuration file generated: ${PWD}/${CLIENT_NAME}.conf"
echo -e "Transfer this file to your client device."
