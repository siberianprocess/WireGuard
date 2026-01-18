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

## 4. Troubleshooting

If your client says it is connected but you cannot access the internet or ping the server:

### Automatic Diagnostics
Run the included troubleshooting script on the server:
```bash
f
```
This checks for common issues like:
- Service status
- IP Forwarding
- Firewall rules (UFW)
- Handshake status

### Common Issues

#### 1. "Handshake" is not completing
If the client sends data (Tx) but receives nothing (Rx: 0), the server is not receiving the packets.
- **Check Cloud Firewall**: Ensure UDP port `51820` is open in your cloud provider's console (AWS Security Groups, DigitalOcean Networking, etc.). UFW status is not enough!
- **Check IP Address**: Verify the `Endpoint` in your client config matches the server's *current* Public IP.

#### 2. Connected but no Internet
- **Check IP Forwarding**: Run `sysctl net.ipv4.ip_forward`. It must be `1`.
- **Check NAT Rules**: The server config must have `POSTROUTING` rules. Rerun `setup_server.sh` if unsure.
- **Check DNS**: Ensure the client config has `DNS = 8.8.8.8` (or another valid DNS).
