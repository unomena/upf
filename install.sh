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
WRAPPER_SCRIPT="upf"
CORE_SCRIPT="upf-core"

# Check if we have access to terminal for interactive input
INTERACTIVE=true
# Simply check if /dev/tty exists and is readable
if ! [ -r /dev/tty ]; then
    INTERACTIVE=false
fi

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

# Read user input safely, even when piped
read_user_input() {
    local prompt="$1"
    local default="${2:-n}"
    local response=""
    
    # Always show the prompt on stderr (which usually goes to terminal)
    echo -e -n "$prompt" >&2
    
    if [[ "$INTERACTIVE" == "true" ]]; then
        # Try to read from /dev/tty if available
        if [ -r /dev/tty ]; then
            read -r response </dev/tty 2>/dev/null || response="$default"
        else
            # Fallback to reading from stdin
            read -r response || response="$default"
        fi
    else
        # Non-interactive mode
        echo " (non-interactive, using default: $default)" >&2
        response="$default"
    fi
    
    # If empty response, use default
    if [[ -z "$response" ]]; then
        response="$default"
    fi
    
    echo "$response"
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

# Install the UPF scripts
install_upf() {
    print_info "Installing UPF..."
    
    # Check if scripts exist in current directory
    local need_download=false
    if [[ -f "./$WRAPPER_SCRIPT" && -f "./$CORE_SCRIPT" ]]; then
        # Local installation - scripts found in current directory
        print_info "Found UPF scripts in current directory"
    else
        need_download=true
        # Remote installation - download from GitHub
        print_info "Downloading UPF scripts from GitHub..."
        
        # Create temp directory for download
        local temp_dir=$(mktemp -d)
        trap "rm -rf $temp_dir" RETURN
        
        # Download both scripts
        if command -v curl &> /dev/null; then
            if ! curl -fsSL "https://raw.githubusercontent.com/unomena/upf/main/$WRAPPER_SCRIPT" -o "$temp_dir/$WRAPPER_SCRIPT"; then
                print_error "Failed to download UPF wrapper script from GitHub"
                exit 1
            fi
            if ! curl -fsSL "https://raw.githubusercontent.com/unomena/upf/main/$CORE_SCRIPT" -o "$temp_dir/$CORE_SCRIPT"; then
                print_error "Failed to download UPF core script from GitHub"
                exit 1
            fi
        elif command -v wget &> /dev/null; then
            if ! wget -q "https://raw.githubusercontent.com/unomena/upf/main/$WRAPPER_SCRIPT" -O "$temp_dir/$WRAPPER_SCRIPT"; then
                print_error "Failed to download UPF wrapper script from GitHub"
                exit 1
            fi
            if ! wget -q "https://raw.githubusercontent.com/unomena/upf/main/$CORE_SCRIPT" -O "$temp_dir/$CORE_SCRIPT"; then
                print_error "Failed to download UPF core script from GitHub"
                exit 1
            fi
        else
            print_error "Neither curl nor wget is available for downloading"
            exit 1
        fi
        
        # Use the downloaded scripts
        cp "$temp_dir/$WRAPPER_SCRIPT" "./$WRAPPER_SCRIPT"
        cp "$temp_dir/$CORE_SCRIPT" "./$CORE_SCRIPT"
        print_success "Downloaded UPF scripts from GitHub"
    fi
    
    # Backup existing installation if present
    if [[ -f "$INSTALL_DIR/$WRAPPER_SCRIPT" ]]; then
        print_warning "Existing installation found"
        backup_file="$INSTALL_DIR/${WRAPPER_SCRIPT}.backup.$(date +%Y%m%d_%H%M%S)"
        cp "$INSTALL_DIR/$WRAPPER_SCRIPT" "$backup_file"
        print_success "Created backup: $backup_file"
    fi
    if [[ -f "$INSTALL_DIR/$CORE_SCRIPT" ]]; then
        backup_file="$INSTALL_DIR/${CORE_SCRIPT}.backup.$(date +%Y%m%d_%H%M%S)"
        cp "$INSTALL_DIR/$CORE_SCRIPT" "$backup_file"
        print_success "Created backup: $backup_file"
    fi
    
    # Copy scripts to installation directory
    cp "./$WRAPPER_SCRIPT" "$INSTALL_DIR/$WRAPPER_SCRIPT"
    cp "./$CORE_SCRIPT" "$INSTALL_DIR/$CORE_SCRIPT"
    chmod +x "$INSTALL_DIR/$WRAPPER_SCRIPT"
    chmod +x "$INSTALL_DIR/$CORE_SCRIPT"
    print_success "Installed UPF wrapper to $INSTALL_DIR/$WRAPPER_SCRIPT"
    print_success "Installed UPF core to $INSTALL_DIR/$CORE_SCRIPT"
    
    # Clean up downloaded scripts if they were fetched
    if [[ "$need_download" == "true" ]]; then
        rm -f "./$WRAPPER_SCRIPT" "./$CORE_SCRIPT"
    fi
}

# Check and enable IP forwarding
setup_ip_forwarding() {
    print_info "Checking IP forwarding configuration..."
    
    current_forwarding=$(sysctl -n net.ipv4.ip_forward 2>/dev/null || echo "0")
    
    if [[ "$current_forwarding" != "1" ]]; then
        print_warning "IP forwarding is currently disabled"
        response=$(read_user_input "  Enable IP forwarding? (recommended) [y/N]: " "n")
        
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
        response=$(read_user_input "  Apply existing rules now? [y/N]: " "n")
        
        if [[ "$response" =~ ^[Yy]$ ]]; then
            print_info "Applying existing rules..."
            if $INSTALL_DIR/$CORE_SCRIPT apply; then
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
        response=$(read_user_input "  Create systemd service for automatic rule application at boot? [y/N]: " "n")
        
        if [[ "$response" =~ ^[Yy]$ ]]; then
            cat > /etc/systemd/system/upf.service << 'EOF'
[Unit]
Description=UPF - Uncomplicated Port Forwarding
After=network.target

[Service]
Type=oneshot
ExecStart=/usr/local/bin/upf-core apply
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
    
    if [[ -x "$INSTALL_DIR/$WRAPPER_SCRIPT" && -x "$INSTALL_DIR/$CORE_SCRIPT" ]]; then
        print_success "UPF is installed and executable"
        
        # Test if it runs (wrapper will handle sudo)
        if $INSTALL_DIR/$WRAPPER_SCRIPT help &> /dev/null; then
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
    echo -e "     ${BOLD}upf help${NC}"
    echo ""
    echo "  2. Add a port forwarding rule:"
    echo -e "     ${BOLD}upf add 8080 192.168.1.100:80${NC}"
    echo ""
    echo "  3. List all rules:"
    echo -e "     ${BOLD}upf list${NC}"
    echo ""
    echo "  4. Remove a rule:"
    echo -e "     ${BOLD}upf remove 8080${NC}"
    echo ""
    echo "Configuration:"
    echo "  • Installed to: $INSTALL_DIR/$WRAPPER_SCRIPT"
    echo "  • Core script: $INSTALL_DIR/$CORE_SCRIPT"
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
    echo -e "  • Run: ${BOLD}upf help${NC}"
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