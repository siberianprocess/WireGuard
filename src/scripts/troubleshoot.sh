#!/bin/bash

# WireGuard Troubleshooting Script
# Usage: sudo ./src/scripts/troubleshoot.sh

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
NC='\033[0m'

# Log setup
LOG_FILE="wg_debug_$(date +%Y%m%d_%H%M%S).log"
exec > >(tee -i "$LOG_FILE") 2>&1

echo -e "${YELLOW}Starting WireGuard Diagnostic..."
echo "Log file: $LOG_FILE"
echo "Time: $(date)${NC}"

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
    
    # Check for Zombie Interface
    if ip link show wg0 >/dev/null 2>&1; then
        echo -e "${RED}[CRITICAL] Interface 'wg0' exists but service is stopped!${NC}"
        echo -e "${YELLOW}This 'zombie' state prevents the service from starting.${NC}"
        echo -e "Fix: Run 'sudo ./src/scripts/reset_server.sh'"
    fi
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

# 5.5 Check Port Usage
echo -e "\n${YELLOW}--- Checking Ports ---${NC}"
if ss -ulpn | grep -q ":51820 "; then
    echo -e "${RED}[FAIL] Port 51820 is already in use!${NC}"
    ss -ulpn | grep ":51820 "
else
    echo -e "${GREEN}[PASS] Port 51820 is free${NC}"
fi

# 5.6 Check IP Address Conflict
echo -e "\n${YELLOW}--- Checking IP Configuration ---${NC}"
if [ -f "/etc/wireguard/wg0.conf" ]; then
    WG_IP=$(grep "Address" /etc/wireguard/wg0.conf | awk '{print $3}' | cut -d/ -f1)
    if [ ! -z "$WG_IP" ]; then
        if ip addr | grep -q "inet $WG_IP"; then
             # It's okay if wg0 has it, but bad if another interface has it and wg0 is down
             if ! ip addr show wg0 2>/dev/null | grep -q "inet $WG_IP"; then
                 echo -e "${RED}[FAIL] IP $WG_IP is already in use by another interface!${NC}"
                 echo -e "${YELLOW}Please change the Address in /etc/wireguard/wg0.conf or re-run setup_server.sh${NC}"
                 ip addr | grep "inet $WG_IP"
             else
                 echo -e "${GREEN}[PASS] IP $WG_IP is assigned to wg0${NC}"
             fi
        else
             echo -e "${GREEN}[PASS] IP $WG_IP is available${NC}"
        fi
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

# 8. Check NAT and Routing (Detailed)
echo -e "\n${YELLOW}--- Checking NAT and Routing ---${NC}"
if iptables -t nat -L POSTROUTING -v -n | grep -q "MASQUERADE"; then
    echo -e "${GREEN}[PASS] NAT Masquerading rule found${NC}"
    echo -e "${YELLOW}NAT Rule Details (Check packet counts):${NC}"
    iptables -t nat -L POSTROUTING -v -n | grep "MASQUERADE"
else
    echo -e "${RED}[FAIL] No NAT Masquerading rule found! Clients won't have internet.${NC}"
fi

# 9. Check MTU
echo -e "\n${YELLOW}--- Checking MTU Settings ---${NC}"
ip link show wg0 | grep mtu
echo -e "${YELLOW}Note: Standard WireGuard MTU is 1420. If connection is slow, try 1280.${NC}"

# 10. Check Handshakes
echo -e "\n${YELLOW}--- Checking Recent Handshakes ---${NC}"
LATEST_HANDSHAKE=$(wg show wg0 latest-handshakes | awk '{print $2}')
if [ "$LATEST_HANDSHAKE" -eq 0 ]; then
     echo -e "${RED}[FAIL] No handshake detected!${NC}"
     echo -e "${YELLOW}Possible causes: UDP 51820 blocked, wrong keys, or wrong public IP.${NC}"
else
     CURRENT_TIME=$(date +%s)
     DIFF=$((CURRENT_TIME - LATEST_HANDSHAKE))
     if [ "$DIFF" -lt 180 ]; then
         echo -e "${GREEN}[PASS] Handshake successful ${DIFF} seconds ago.${NC}"
     else
         echo -e "${RED}[FAIL] Last handshake was ${DIFF} seconds ago (too long).${NC}"
     fi
fi

# 11. Kernel Logs for WireGuard
echo -e "\n${YELLOW}--- Kernel Log Errors (Last 10) ---${NC}"
dmesg | grep -i wireguard | tail -n 10

echo -e "\n${YELLOW}Diagnostic Complete. Log saved to ${LOG_FILE}${NC}"
echo -e "${YELLOW}Please send this file to the support agent.${NC}"
echo -e "${YELLOW}NOTE: If everything passes but clients cannot connect:${NC}"
echo -e "1. Check your **Cloud Provider Firewall** (AWS Security Groups, DigitalOcean Firewalls, etc.)."
echo -e "   - Ensure UDP port 51820 is open Inbound."
echo -e "2. Check Client Configuration."
echo -e "   - Ensure 'Endpoint' IP matches the server's PUBLIC IP."
echo -e "   - Ensure 'AllowedIPs' is set to 0.0.0.0/0 (for full tunnel) or specific subnets."
echo -e "3. Check logs: 'dmesg -wT' or 'journalctl -u wg-quick@wg0 -f'"
