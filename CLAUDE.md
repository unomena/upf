# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

UPF (Uncomplicated Port Forwarding) is a Bash-based utility that simplifies iptables port forwarding management on Linux systems. It provides a user-friendly interface for creating, managing, and persisting port forwarding rules with automatic sudo handling and hostname resolution.

## Architecture

### Two-Script Architecture

1. **Wrapper Script (`upf`)**: Entry point that handles sudo elevation
   - Automatically detects if running as root
   - Elevates privileges via sudo when needed
   - Allows users to run commands without typing sudo
   - Falls back to development directory for testing

2. **Core Script (`upf-core`)**: Actual implementation
   - Configuration management via `/etc/upf/rules.conf`
   - iptables rule manipulation with custom comment tagging (`UPF_<port>`)
   - Hostname resolution (forward and reverse DNS)
   - JSON output support via `--json` flag for programmatic access

3. **Installation System**:
   - `install.sh`: Automated installer with no user prompts
   - Automatically enables IP forwarding
   - Creates systemd service for rule persistence
   - Downloads both scripts from GitHub when needed

### Key Design Patterns

- **Rule Tagging**: All iptables rules are tagged with comments prefixed with `UPF_` for easy identification and cleanup
- **Configuration Persistence**: Rules are stored in `/etc/upf/rules.conf` in format: `local_port:dest_ip:dest_port` (always stores resolved IPs, not hostnames)
- **Hostname Resolution**: 
  - Forward resolution via `resolve_hostname()` using getent, host, nslookup, dig, /etc/hosts
  - Reverse resolution via `reverse_resolve_ip()` for displaying hostnames in list output
  - Resolved IPs are stored for reliability even if DNS changes
- **IP Forwarding Management**: Automatically enables and persists `net.ipv4.ip_forward` sysctl setting
- **Special IP Handling**: Shortcuts for common IPs (localhost, 127.*, 0.0.0.0)
- **JSON API**: The `list --json` command outputs machine-readable JSON including hostname field when resolvable

### iptables Rule Structure

For each forwarding rule, UPF creates:
1. **PREROUTING rule** (NAT table): DNAT for incoming connections
2. **FORWARD rule**: Allows forwarded traffic
3. **OUTPUT rule** (NAT table, localhost only): Handles local-to-local forwarding

## Development Commands

### Testing Changes Locally

```bash
# Test wrapper and core scripts (wrapper handles sudo automatically)
./upf list
./upf list --json
./upf add 8080 80
./upf add 8001 webserver.local:8000  # Test hostname resolution
./upf remove 8080
./upf apply  # Re-apply all saved rules
./upf clean  # Remove all UPF-managed rules

# Verify iptables rules directly
sudo iptables -t nat -L PREROUTING -n -v --line-numbers
sudo iptables -L FORWARD -n -v --line-numbers
sudo iptables -t nat -L OUTPUT -n -v --line-numbers  # For localhost rules

# Test JSON output parsing
./upf list --json | jq '.rules'

# Check configuration file
cat /etc/upf/rules.conf

# Validate bash syntax
bash -n upf
bash -n upf-core
bash -n install.sh
```

### Installation and Deployment

```bash
# Remote installation (production)
curl -fsSL https://raw.githubusercontent.com/unomena/upf/main/install.sh | sudo bash

# Cache-busting installation (if GitHub CDN is caching old version)
curl -fsSL "https://raw.githubusercontent.com/unomena/upf/main/install.sh?$(date +%s)" | sudo bash

# Local installation from repository
sudo bash install.sh

# Manual installation of both scripts
sudo cp upf upf-core /usr/local/bin/
sudo chmod +x /usr/local/bin/upf /usr/local/bin/upf-core
```

### Systemd Service

The installer automatically creates and enables a systemd service:
```bash
# Service location: /etc/systemd/system/upf.service
# Check status
systemctl status upf.service

# View logs
journalctl -u upf.service

# Manually trigger rule application
systemctl restart upf.service
```

## Key Implementation Details

- **Privilege Handling**: Wrapper script (`upf`) automatically elevates to root via sudo, core script (`upf-core`) expects root
- **Configuration Storage**: `/etc/upf/rules.conf` stores `local_port:resolved_ip:dest_port` (IPs only, not hostnames)
- **Hostname Resolution Order**: getent → host → nslookup → dig → /etc/hosts direct lookup
- **IP Forwarding**: Automatically enabled and persisted in `/etc/sysctl.conf`
- **Silent Operations**: Rule removal is silent when called internally (e.g., during replacements)
- **JSON Output Format**: `{"rules": [{"local_port": N, "destination_ip": "IP", "destination_port": N, "hostname": "NAME", "status": "active|inactive"}]}`
- **GitHub Repository**: Always use `unomena/upf` for URLs
- **Bash Requirements**: Requires bash 4.0+ for associative arrays and pattern matching
- **iptables Safety**: All rules tagged with `UPF_<port>` comments for safe identification

## Code Modification Guidelines

- **Wrapper (`upf`)**: Keep minimal, only handle sudo elevation logic
- **Core (`upf-core`)**: All business logic goes here
- **Rule Tagging**: Always use `IPTABLES_COMMENT_PREFIX` variable for consistency
- **Config Format**: Preserve `port:ip:port` format for backward compatibility
- **Error Messages**: Include specific error details and suggested fixes
- **Input Validation**: Validate all user input before iptables operations
- **Hostname Storage**: Always store resolved IPs in config, never hostnames
- **Testing**: Test both direct execution and via wrapper

## Debugging

```bash
# Enable bash debug mode
bash -x upf list  # Wrapper will handle sudo
sudo bash -x upf-core list  # Direct core execution

# Check iptables rules with UPF tags
sudo iptables-save | grep UPF

# Monitor iptables changes in real-time
watch -n1 'sudo iptables -t nat -L PREROUTING -n | grep -A2 "^Chain\|UPF"'

# Test hostname resolution functions
sudo bash -c 'source upf-core && resolve_hostname "google.com"'
sudo bash -c 'source upf-core && reverse_resolve_ip "8.8.8.8"'

# Check systemd service
systemctl status upf.service
journalctl -u upf.service -f

# Verify configuration integrity
sudo cat /etc/upf/rules.conf
sudo upf list --json | jq .
```