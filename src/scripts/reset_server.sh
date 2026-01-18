#!/bin/bash

# WireGuard Reset Script
# Usage: sudo ./src/scripts/reset_server.sh
# Purpose: Cleans up "zombie" interfaces and restarts the service.

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
NC='\033[0m'

if [ "$EUID" -ne 0 ]; then
  echo -e "${RED}Please run as root${NC}"
  exit 1
fi

echo -e "${YELLOW}Stopping WireGuard service...${NC}"
systemctl stop wg-quick@wg0 || true

echo -e "${YELLOW}Checking for zombie 'wg0' interface...${NC}"
if ip link show wg0 >/dev/null 2>&1; then
    echo -e "${YELLOW}Interface wg0 exists. Removing manually...${NC}"
    ip link delete wg0
    echo -e "${GREEN}Interface removed.${NC}"
else
    echo -e "${GREEN}No zombie interface found.${NC}"
fi

echo -e "${YELLOW}Restarting WireGuard service...${NC}"
systemctl start wg-quick@wg0 || true

if systemctl is-active --quiet wg-quick@wg0; then
    echo -e "${GREEN}WireGuard reset successfully and is now RUNNING!${NC}"
else
    echo -e "${RED}Failed to start WireGuard.${NC}"
    echo -e "${YELLOW}Last 20 lines of service logs:${NC}"
    journalctl -u wg-quick@wg0 -n 20 --no-pager
    
    echo -e "\n${YELLOW}Checking for 'Address already in use' errors:${NC}"
    journalctl -u wg-quick@wg0 --no-pager | grep "Address already in use" | tail -n 2
    
    exit 1
fi
