# Deployment Guide

## Prerequisites

- **OS**: Ubuntu 20.04 or 22.04 LTS
- **Permissions**: Root access (sudo)
- **Networking**: Public static IP address (recommended)
- **Ports**: UDP port 51820 must be open on your cloud provider's firewall

## 1. Server Setup

1.  Connect to your server via SSH.
2.  Clone this repository or copy the scripts to your server.
3.  Make the script executable:
    ```bash
    chmod +x src/scripts/setup_server.sh
    ```
4.  Run the setup script:
    ```bash
    sudo ./src/scripts/setup_server.sh
    ```
    
    This script will:
    - Install WireGuard
    - Generate keys
    - Configure `/etc/wireguard/wg0.conf`
    - Enable IP forwarding
    - Configure UFW
    - Start the WireGuard interface

## 2. Adding a Client

1.  Make the client script executable:
    ```bash
    chmod +x src/scripts/add_client.sh
    ```
2.  Run the script with a client name:
    ```bash
    sudo ./src/scripts/add_client.sh my-laptop
    ```
    
    This will:
    - Generate client keys
    - Add the client to the server config
    - Generate a client configuration file (`my-laptop.conf`)
    - Reload the server

3.  Transfer the generated `.conf` file to your client device.

## 3. Client Connection

- **Desktop/Mobile**: Import the `.conf` file into the WireGuard app.
- **Linux**: Copy to `/etc/wireguard/wg0.conf` and run `sudo wg-quick up wg0`.
