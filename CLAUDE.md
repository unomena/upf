# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

UPF (Uncomplicated Port Forwarding) is a Bash-based utility that simplifies iptables port forwarding management on Linux systems. It provides a user-friendly interface for creating, managing, and persisting port forwarding rules.

## Architecture

### Core Components

1. **Main Script (`upf`)**: A single Bash script that manages all functionality
   - Configuration management via `/etc/upf/rules.conf`
   - iptables rule manipulation with custom comment tagging (`UPF_<port>`)
   - Persistent rule storage and restoration
   - JSON output support via `--json` flag for programmatic access

2. **Installation System**:
   - `install.sh`: Full installer with system checks, systemd integration, and IP forwarding setup
   - `get.sh`: Quick installer that downloads and runs install.sh from GitHub

### Key Design Patterns

- **Rule Tagging**: All iptables rules are tagged with comments prefixed with `UPF_` for easy identification and cleanup
- **Configuration Persistence**: Rules are stored in `/etc/upf/rules.conf` in format: `local_port:dest_ip:dest_port`
- **IP Forwarding Management**: Automatically enables and persists `net.ipv4.ip_forward` sysctl setting
- **Special IP Handling**: Shortcuts for common IPs (localhost, 127.*, 0.0.0.0)
- **JSON API**: The `list --json` command outputs machine-readable JSON for automation/integration

### iptables Rule Structure

For each forwarding rule, UPF creates:
1. **PREROUTING rule** (NAT table): DNAT for incoming connections
2. **FORWARD rule**: Allows forwarded traffic
3. **OUTPUT rule** (NAT table, localhost only): Handles local-to-local forwarding

## Common Development Tasks

### Testing Changes

```bash
# Test the script directly (requires sudo)
sudo ./upf list
sudo ./upf list --json
sudo ./upf add 8080 80
sudo ./upf remove 8080

# Verify iptables rules
sudo iptables -t nat -L PREROUTING -n -v --line-numbers
sudo iptables -L FORWARD -n -v --line-numbers

# Test JSON output parsing
sudo ./upf list --json | jq '.rules'
```

### Installation

```bash
# Quick install from GitHub
curl -fsSL https://raw.githubusercontent.com/unomena/upf/main/get.sh | bash

# Manual install from local directory
sudo bash install.sh

# Direct binary installation
sudo cp upf /usr/local/bin/
sudo chmod +x /usr/local/bin/upf
```

### Systemd Integration

The installer can create a systemd service for automatic rule restoration:
```bash
# Service file location: /etc/systemd/system/upf.service
# Enable: systemctl enable upf.service
# Status: systemctl status upf.service
```

## Important Implementation Notes

- The script requires root privileges (enforced by `check_root()` function)
- Configuration directory `/etc/upf/` is created automatically if missing
- IP forwarding is enabled automatically and made persistent via `/etc/sysctl.conf`
- Rule removal is silent when called internally (e.g., during rule replacement)
- The `apply` command re-adds all saved rules, useful for system restarts
- JSON output format: `{"rules": [{"local_port": N, "destination_ip": "IP", "destination_port": N, "status": "active|inactive"}]}`
- Repository URL references should use `unomena/upf` on GitHub