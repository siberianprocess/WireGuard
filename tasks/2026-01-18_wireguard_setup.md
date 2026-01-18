# Task: Create WireGuard Setup Scripts

**Date Started**: 2026-01-18
**Status**: In Progress
**Priority**: High
**Assigned To**: AI

---

## 📋 Description

Create a set of bash scripts to automate the installation and configuration of WireGuard on an Ubuntu server, and to efficiently generate client configurations.

## 🎯 Goals

1.  **Server Setup Script (`setup_server.sh`)**:
    - Install WireGuard on Ubuntu.
    - Configure the server interface (`wg0`).
    - Enable IP forwarding.
    - Configure firewall (UFW/iptables).
    - Start and enable the service.

2.  **Client Setup Script (`add_client.sh`)**:
    - Generate private/public keys for the client.
    - Generate pre-shared key (optional but recommended).
    - Create a client configuration file (`.conf`).
    - Add the client peer to the server configuration.
    - Reload the server configuration.
    - Output the path to the generated client configuration file.

## 📁 Files to be Modified/Created

- [ ] `src/scripts/setup_server.sh`
- [ ] `src/scripts/add_client.sh`
- [ ] `README.md`
- [ ] `docs/DEPLOYMENT.md`

## 🗺️ Work Plan

### Step 1: Research and Design (Estimated: 10 min) ✅
- [x] Define WireGuard configuration structure (IP ranges, ports).
- [x] Design script arguments and flows.

### Step 2: Server Script Implementation (Estimated: 30 min) ✅
- [x] Implement dependency installation.
- [x] Implement key generation.
- [x] Implement config file creation.
- [x] Implement firewall rules.

### Step 3: Client Script Implementation (Estimated: 30 min) ✅
- [x] Implement key generation.
- [x] Implement config generation.
- [x] Implement server config update.

### Step 4: Documentation (Estimated: 10 min) ✅
- [x] Create README with usage instructions.

## 📝 Progress Notes

**2026-01-18** — Task started. Project structure initialized.
**2026-01-18** — Implementation plan approved. Starting server script.
**2026-01-18** — Server script implemented and documented. Starting client script.
**2026-01-18** — Client script implemented. Syntax updated.

## ✅ Completion Checklist

- [x] Code written and tested
- [x] Documentation updated
- [x] Code reviewed
- [x] Fixed IP detection bug (HTML response from ifconfig.me)
