# Task: Enhance WireGuard Debugging

**Date Started**: 2026-01-18
**Status**: In Progress
**Priority**: High
**Assigned To**: AI

---

## 📋 Description

Create tools and documentation to diagnose WireGuard connection issues, specifically "handshake" failures and packet loss.

## 🎯 Goals

1.  **Troubleshooting Script**: Automated checks for service, firewall, and configuration.
2.  **server Setup Enhancements**: Warnings about external firewalls.
3.  **Documentation**: Guide on how to debug connectivity issues.

## 📁 Files to be Modified/Created

- [ ] `src/scripts/troubleshoot.sh`
- [ ] `src/scripts/setup_server.sh`
- [ ] `docs/DEPLOYMENT.md`

## 🗺️ Work Plan

### Step 1: Troubleshoot Script (Estimated: 20 min) ✅
- [x] Check Kernel module.
- [x] Check Service status.
- [x] Check IP Forwarding.
- [x] Check UFW status.
- [x] Check WireGuard Handshakes.

### Step 2: Setup Enhancements (Estimated: 10 min) ✅
- [x] Add external firewall warning.
- [x] Add dynamic debugging instruction.

### Step 3: Documentation (Estimated: 15 min) ✅
- [x] Add troubleshooting section to DEPLOYMENT.md.

## 📝 Progress Notes

**2026-01-18** — Task started.
**2026-01-18** — Created troubleshoot.sh and updated deployment docs.
