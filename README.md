# UPF - Uncomplicated Port Forwarding

![License](https://img.shields.io/badge/license-MIT-blue.svg)
![Platform](https://img.shields.io/badge/platform-Linux-green.svg)
![Shell](https://img.shields.io/badge/shell-bash-orange.svg)

UPF (Uncomplicated Port Forwarding) is a simple, user-friendly command-line tool for managing iptables port forwarding rules on Linux systems. Inspired by UFW (Uncomplicated Firewall), UPF makes it easy to set up and manage port forwarding without dealing with complex iptables syntax.

## Features

- **Simple Commands**: Easy-to-remember commands similar to UFW
- **Persistent Rules**: Automatically saves rules that persist across reboots
- **Status Monitoring**: Check which rules are active or inactive
- **Automatic IP Forwarding**: Enables kernel IP forwarding automatically
- **Smart IP Handling**: Convenient shortcuts for localhost and common IPs
- **Safe Rule Management**: Tagged rules prevent conflicts with other iptables configurations
- **Batch Operations**: Apply all rules at once or clean everything with a single command

## Installation

### Quick Install

```bash
# Standard installation
curl -fsSL https://raw.githubusercontent.com/unomena/upf/main/install.sh | sudo bash

# If you're having issues with cached versions, use:
curl -fsSL "https://raw.githubusercontent.com/unomena/upf/main/install.sh?$(date +%s)" | sudo bash
```

### Manual Install

```bash
# Clone the repository
git clone https://github.com/unomena/upf.git
cd upf

# Copy to system path
sudo cp upf /usr/local/bin/
sudo chmod +x /usr/local/bin/upf

# Verify installation
upf help
```

## Usage

UPF automatically handles root privileges, so you don't need to use `sudo`.

### Basic Commands

```bash
# List all port forwarding rules
upf list

# Add a new port forwarding rule
upf add <from_port> <destination>

# Remove a port forwarding rule
upf remove <port>

# Apply all saved rules (useful after reboot)
upf apply

# Remove all UPF rules
upf clean

# Show help
upf help
```

### Examples

#### Forward to Another Machine

Forward incoming traffic on port 8080 to an internal server:

```bash
# Forward port 8080 to 192.168.1.30 on port 80
upf add 8080 192.168.1.30:80

# Forward HTTPS traffic to internal server
upf add 443 10.0.0.5:443
```

#### Local Port Forwarding

Forward traffic between ports on the same machine:

```bash
# Forward port 8080 to local port 80
upf add 8080 80

# Useful for development - forward port 3000 to 3001
upf add 3000 3001
```

#### Managing Rules

```bash
# View all configured rules and their status
upf list

# Remove a specific forwarding rule
upf remove 8080

# Apply all saved rules (after system restart)
upf apply

# Remove all port forwarding rules
upf clean
```

### Destination Formats

UPF supports two destination formats:

- `<ip>:<port>` - Forward to a specific IP address and port
- `<port>` - Forward to localhost on the specified port

### Special IP Shortcuts

UPF provides convenient shortcuts for common IP addresses:

- `localhost`, `home`, `127*`, `lo` → `127.0.0.1`
- `0.0.0.0`, `0`, `000` → `0.0.0.0` (all interfaces)

## How It Works

UPF manages iptables rules by:

1. **Creating NAT rules**: Sets up DNAT rules in the PREROUTING chain for incoming traffic
2. **Allowing forwarded traffic**: Adds FORWARD rules to permit the traffic
3. **Handling local traffic**: Creates OUTPUT rules for localhost destinations
4. **Tagging rules**: All rules are tagged with comments for easy identification
5. **Persisting configuration**: Saves rules to `/etc/upf/rules.conf` for persistence

### File Locations

- **Configuration**: `/etc/upf/rules.conf`
- **Executable**: `/usr/local/bin/upf`

## System Requirements

- Linux operating system
- Bash shell (4.0+)
- iptables installed
- Root/sudo access

## Troubleshooting

### Rules Not Working After Reboot

Run `upf apply` to restore all saved rules. The installer can set up a systemd service to do this automatically.

### Port Already in Use

If you get an error about a port already being in use, check existing rules with `upf list` and remove conflicting rules.

### IP Forwarding Not Working

UPF automatically enables IP forwarding, but you can verify with:

```bash
sysctl net.ipv4.ip_forward
```

If it shows `0`, enable it manually:

```bash
sudo sysctl -w net.ipv4.ip_forward=1
```

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request. For major changes, please open an issue first to discuss what you would like to change.

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit your changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

### Development

To test changes locally:

```bash
# Run directly from the repository
./upf list

# Test adding rules
./upf add 8080 80

# Verify iptables rules (requires sudo)
sudo iptables -t nat -L PREROUTING -n -v --line-numbers
```

## Security Considerations

- UPF automatically uses sudo when needed to modify iptables rules
- Port forwarding can expose internal services - use with caution
- Always verify the destination before creating rules
- Consider using firewall rules to restrict source IPs for sensitive services

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Acknowledgments

- Inspired by [UFW (Uncomplicated Firewall)](https://launchpad.net/ufw)
- Built on top of iptables and netfilter

## Support

If you encounter any issues or have questions:

1. Check the [Issues](https://github.com/unomena/upf/issues) page
2. Review the help: `upf help`
3. Open a new issue with details about your problem

## Roadmap

- [ ] Support for UDP forwarding
- [ ] Port range forwarding
- [ ] Source IP restrictions
- [ ] Integration with systemd for automatic rule application
- [ ] Web UI for rule management
- [ ] Export/import rule configurations
- [ ] IPv6 support
