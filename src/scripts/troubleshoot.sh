#!/bin/bash

# WireGuard Troubleshooting Script
# Usage: sudo ./src/scripts/troubleshoot.sh

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
NC='\033[0m'

echo -e "${YELLOW}Starting WireGuard Diagnostic...${NC}"

# 1. Check Root
if [ "$EUID" -ne 0 ]; then
  echo -e "${RED}[FAIL] Please run as root${NC}"
  exit 1
fi

# 2. Check Kernel Module
if lsmod | grep -q wireguard; then
    echo -e "${GREEN}[PASS] WireGuard module loaded${NC}"
else
    echo -e "${RED}[FAIL] WireGuard module NOT loaded${NC}"
fi

# 3. Check Service Status
if systemctl is-active --quiet wg-quick@wg0; then
    echo -e "${GREEN}[PASS] Service wg-quick@wg0 is active${NC}"
else
    echo -e "${RED}[FAIL] Service wg-quick@wg0 is NOT active${NC}"
    echo "Try: systemctl status wg-quick@wg0"
fi

# 4. Check IP Forwarding
IP_FWD=$(sysctl net.ipv4.ip_forward | awk '{print $3}')
if [ "$IP_FWD" == "1" ]; then
    echo -e "${GREEN}[PASS] IP Forwarding enabled${NC}"
else
    echo -e "${RED}[FAIL] IP Forwarding DISABLED (Value: $IP_FWD)${NC}"
    echo "Try: sysctl -w net.ipv4.ip_forward=1"
fi

# 5. Check UFW
if command -v ufw > /dev/null; then
    if ufw status | grep -q "Status: active"; then
        echo -e "${GREEN}[PASS] UFW is active${NC}"
        if ufw status | grep -q "51820/udp"; then
             echo -e "${GREEN}[PASS] UFW allows 51820/udp${NC}"
        else
             echo -e "${RED}[FAIL] UFW does NOT explicitly allow 51820/udp${NC}"
        fi
    else
        echo -e "${YELLOW}[WARN] UFW is inactive (Firewall might be off or managed by iptables)${NC}"
    fi
fi

# 6. Check Configuration File
if [ -f "/etc/wireguard/wg0.conf" ]; then
    echo -e "${GREEN}[PASS] Config file found (/etc/wireguard/wg0.conf)${NC}"
else
    echo -e "${RED}[FAIL] Config file NOT found${NC}"
fi

# 7. Check Handshakes (Peer Connection Status)
echo -e "\n${YELLOW}--- Peer Status (wg show) ---${NC}"
wg show wg0

echo -e "\n${YELLOW}--- Diagnostics Complete ---${NC}"
echo -e "${YELLOW}NOTE: If everything passes but clients cannot connect:${NC}"
echo -e "1. Check your **Cloud Provider Firewall** (AWS Security Groups, DigitalOcean Firewalls, etc.)."
echo -e "   - Ensure UDP port 51820 is open Inbound."
echo -e "2. Check Client Configuration."
echo -e "   - Ensure 'Endpoint' IP matches the server's PUBLIC IP."
echo -e "   - Ensure 'AllowedIPs' is set to 0.0.0.0/0 (for full tunnel) or specific subnets."
echo -e "3. Check logs: 'dmesg -wT' or 'journalctl -u wg-quick@wg0 -f'"
