#!/bin/bash

#############################################################################
# UPF (Uncomplicated Port Forwarding) Installer
# 
# This script installs UPF on your system
# Requirements: Linux with iptables support
#############################################################################

set -euo pipefail

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
BOLD='\033[1m'
NC='\033[0m' # No Color

# Installation paths
INSTALL_DIR="/usr/local/bin"
CONFIG_DIR="/etc/upf"
SCRIPT_NAME="upf"

# Functions for colored output
print_header() {
    echo -e "${BOLD}"
    echo "╔═══════════════════════════════════════════════════════════════╗"
    echo "║              UPF - Uncomplicated Port Forwarding              ║"
    echo "║                     Installation Script                       ║"
    echo "╚═══════════════════════════════════════════════════════════════╝"
    echo -e "${NC}"
}

print_success() {
    echo -e "${GREEN}✓ $1${NC}"
}

print_error() {
    echo -e "${RED}✗ $1${NC}"
}

print_info() {
    echo -e "${BLUE}→ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠ $1${NC}"
}

# Check if running as root
check_root() {
    if [[ $EUID -ne 0 ]]; then
        print_error "This installer must be run as root (use sudo)"
        echo "  Usage: sudo bash install.sh"
        exit 1
    fi
}

# Check system requirements
check_requirements() {
    print_info "Checking system requirements..."
    
    # Check if Linux
    if [[ "$(uname -s)" != "Linux" ]]; then
        print_error "UPF requires Linux operating system"
        exit 1
    fi
    
    # Check for iptables
    if ! command -v iptables &> /dev/null; then
        print_error "iptables is not installed"
        echo "  Please install iptables first:"
        echo "  Debian/Ubuntu: sudo apt-get install iptables"
        echo "  RHEL/CentOS: sudo yum install iptables"
        exit 1
    fi
    
    # Check for bash
    if ! command -v bash &> /dev/null; then
        print_error "bash is not installed"
        exit 1
    fi
    
    print_success "All requirements met"
}

# Create configuration directory
create_config_dir() {
    print_info "Setting up configuration directory..."
    
    if [[ ! -d "$CONFIG_DIR" ]]; then
        mkdir -p "$CONFIG_DIR"
        print_success "Created configuration directory: $CONFIG_DIR"
    else
        print_success "Configuration directory already exists: $CONFIG_DIR"
    fi
    
    # Create empty rules file if it doesn't exist
    if [[ ! -f "$CONFIG_DIR/rules.conf" ]]; then
        touch "$CONFIG_DIR/rules.conf"
        chmod 644 "$CONFIG_DIR/rules.conf"
        print_success "Created rules configuration file"
    else
        print_warning "Rules configuration file already exists"
    fi
}

# Install the UPF script
install_upf() {
    print_info "Installing UPF..."
    
    # Check if script exists in current directory
    if [[ ! -f "./$SCRIPT_NAME" ]]; then
        print_error "UPF script not found in current directory"
        echo "  Please run this installer from the UPF directory"
        exit 1
    fi
    
    # Backup existing installation if present
    if [[ -f "$INSTALL_DIR/$SCRIPT_NAME" ]]; then
        print_warning "Existing installation found"
        backup_file="$INSTALL_DIR/${SCRIPT_NAME}.backup.$(date +%Y%m%d_%H%M%S)"
        cp "$INSTALL_DIR/$SCRIPT_NAME" "$backup_file"
        print_success "Created backup: $backup_file"
    fi
    
    # Copy script to installation directory
    cp "./$SCRIPT_NAME" "$INSTALL_DIR/$SCRIPT_NAME"
    chmod +x "$INSTALL_DIR/$SCRIPT_NAME"
    print_success "Installed UPF to $INSTALL_DIR/$SCRIPT_NAME"
}

# Check and enable IP forwarding
setup_ip_forwarding() {
    print_info "Checking IP forwarding configuration..."
    
    current_forwarding=$(sysctl -n net.ipv4.ip_forward 2>/dev/null || echo "0")
    
    if [[ "$current_forwarding" != "1" ]]; then
        print_warning "IP forwarding is currently disabled"
        echo -n "  Enable IP forwarding? (recommended) [y/N]: "
        read -r response
        
        if [[ "$response" =~ ^[Yy]$ ]]; then
            # Enable immediately
            sysctl -w net.ipv4.ip_forward=1 >/dev/null 2>&1
            
            # Make persistent
            if ! grep -q "^net.ipv4.ip_forward=1" /etc/sysctl.conf 2>/dev/null; then
                echo "net.ipv4.ip_forward=1" >> /etc/sysctl.conf
            fi
            
            print_success "IP forwarding enabled and made persistent"
        else
            print_warning "IP forwarding not enabled (UPF will enable it when adding rules)"
        fi
    else
        print_success "IP forwarding is already enabled"
    fi
}

# Apply existing rules
apply_existing_rules() {
    if [[ -s "$CONFIG_DIR/rules.conf" ]]; then
        print_info "Found existing port forwarding rules"
        echo -n "  Apply existing rules now? [y/N]: "
        read -r response
        
        if [[ "$response" =~ ^[Yy]$ ]]; then
            print_info "Applying existing rules..."
            if $INSTALL_DIR/$SCRIPT_NAME apply; then
                print_success "Existing rules applied successfully"
            else
                print_warning "Failed to apply some rules"
            fi
        fi
    fi
}

# Create systemd service for automatic rule application (optional)
setup_systemd_service() {
    if command -v systemctl &> /dev/null; then
        print_info "Systemd detected"
        echo -n "  Create systemd service for automatic rule application at boot? [y/N]: "
        read -r response
        
        if [[ "$response" =~ ^[Yy]$ ]]; then
            cat > /etc/systemd/system/upf.service << 'EOF'
[Unit]
Description=UPF - Uncomplicated Port Forwarding
After=network.target

[Service]
Type=oneshot
ExecStart=/usr/local/bin/upf apply
RemainAfterExit=yes

[Install]
WantedBy=multi-user.target
EOF
            
            systemctl daemon-reload
            systemctl enable upf.service
            print_success "Systemd service created and enabled"
            print_info "Rules will be automatically applied on system boot"
        fi
    fi
}

# Verify installation
verify_installation() {
    print_info "Verifying installation..."
    
    if [[ -x "$INSTALL_DIR/$SCRIPT_NAME" ]]; then
        print_success "UPF is installed and executable"
        
        # Test if it runs
        if $INSTALL_DIR/$SCRIPT_NAME help &> /dev/null; then
            print_success "UPF is working correctly"
        else
            print_warning "UPF installed but may have issues"
        fi
    else
        print_error "Installation verification failed"
        exit 1
    fi
}

# Display post-installation information
show_completion_message() {
    echo ""
    echo -e "${GREEN}${BOLD}═══════════════════════════════════════════════════════════════${NC}"
    echo -e "${GREEN}${BOLD}✓ UPF Installation Complete!${NC}"
    echo -e "${GREEN}${BOLD}═══════════════════════════════════════════════════════════════${NC}"
    echo ""
    echo "Quick Start Guide:"
    echo ""
    echo "  1. View help and available commands:"
    echo "     ${BOLD}upf help${NC}"
    echo ""
    echo "  2. Add a port forwarding rule:"
    echo "     ${BOLD}sudo upf add 8080 192.168.1.100:80${NC}"
    echo ""
    echo "  3. List all rules:"
    echo "     ${BOLD}sudo upf list${NC}"
    echo ""
    echo "  4. Remove a rule:"
    echo "     ${BOLD}sudo upf remove 8080${NC}"
    echo ""
    echo "Configuration:"
    echo "  • Installed to: $INSTALL_DIR/$SCRIPT_NAME"
    echo "  • Config directory: $CONFIG_DIR"
    echo "  • Rules file: $CONFIG_DIR/rules.conf"
    echo ""
    
    if systemctl is-enabled upf.service &> /dev/null 2>&1; then
        echo "Automatic startup:"
        echo "  • Systemd service is enabled"
        echo "  • Rules will be applied automatically on boot"
        echo ""
    fi
    
    echo "For more information:"
    echo "  • Run: ${BOLD}upf help${NC}"
    echo "  • Visit: https://github.com/unomena/upf"
    echo ""
}

# Main installation process
main() {
    print_header
    
    check_root
    check_requirements
    create_config_dir
    install_upf
    setup_ip_forwarding
    apply_existing_rules
    setup_systemd_service
    verify_installation
    show_completion_message
}

# Run the installer
main "$@"