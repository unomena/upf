#!/bin/bash

#############################################################################
# UPF Quick Installer
# 
# Downloads the full repository and runs the installation script.
# Usage: curl -fsSL https://raw.githubusercontent.com/unomena/upf/main/get.sh | bash
#        or
#        wget -qO- https://raw.githubusercontent.com/unomena/upf/main/get.sh | bash
#############################################################################

set -euo pipefail

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
BOLD='\033[1m'
NC='\033[0m'

# Display header
echo -e "${BOLD}"
echo "╔═══════════════════════════════════════════════════════════════╗"
echo "║                   UPF Quick Installer                         ║"
echo "║          Uncomplicated Port Forwarding for Linux              ║"
echo "╚═══════════════════════════════════════════════════════════════╝"
echo -e "${NC}"

# Check if running on Linux
if [[ "$(uname -s)" != "Linux" ]]; then
    echo -e "${RED}Error: UPF requires Linux operating system${NC}"
    exit 1
fi

# Check for curl or wget
if ! command -v curl &> /dev/null && ! command -v wget &> /dev/null; then
    echo -e "${RED}Error: Neither curl nor wget is installed${NC}"
    echo "Please install one of them first:"
    echo "  Debian/Ubuntu: sudo apt-get install curl"
    echo "  RHEL/CentOS: sudo yum install curl"
    exit 1
fi

# Create temp directory
TEMP_DIR=$(mktemp -d)
trap "rm -rf $TEMP_DIR" EXIT

echo -e "${BLUE}→ Creating temporary directory...${NC}"
cd "$TEMP_DIR"

# Download the repository
echo -e "${BLUE}→ Downloading UPF from GitHub...${NC}"
if command -v curl &> /dev/null; then
    curl -fsSL https://github.com/unomena/upf/archive/main.tar.gz -o upf.tar.gz
else
    wget -q https://github.com/unomena/upf/archive/main.tar.gz -O upf.tar.gz
fi

# Extract the archive
echo -e "${BLUE}→ Extracting files...${NC}"
tar -xzf upf.tar.gz
cd upf-main

# Check if install.sh exists
if [[ ! -f "install.sh" ]]; then
    echo -e "${RED}Error: install.sh not found in repository${NC}"
    exit 1
fi

# Check if upf script exists
if [[ ! -f "upf" ]]; then
    echo -e "${RED}Error: upf script not found in repository${NC}"
    exit 1
fi

# Make scripts executable
chmod +x install.sh upf

# Run the install script with sudo
echo -e "${BLUE}→ Running installation (requires sudo)...${NC}"
echo ""

# Check if we already have sudo or are root
if [[ $EUID -eq 0 ]]; then
    # Already root
    bash install.sh
else
    # Need sudo
    if command -v sudo &> /dev/null; then
        sudo bash install.sh
    else
        echo -e "${YELLOW}Warning: sudo not found, attempting to run with su${NC}"
        echo "Please enter root password:"
        su -c "cd '$PWD' && bash install.sh"
    fi
fi

# Installation complete
echo ""
echo -e "${GREEN}${BOLD}✓ Quick installation completed!${NC}"
echo ""
echo "Get started with:"
echo "  ${BOLD}upf help${NC}        - Show all available commands"
echo "  ${BOLD}sudo upf list${NC}   - List current port forwarding rules"
echo "  ${BOLD}sudo upf add 8080 80${NC} - Forward port 8080 to 80"
echo ""
echo "For more information, visit: https://github.com/unomena/upf"