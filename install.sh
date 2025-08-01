#!/bin/bash
#
# install.sh - Quick installation script for Ubuntu Optimize Toolkit
# 
# This script provides a one-liner installation for the Ubuntu Optimize Toolkit
# Usage: curl -fsSL https://raw.githubusercontent.com/dip-roy/ubuntu-optimize/main/install.sh | bash

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m' # No Color

# Installation directory
INSTALL_DIR="$HOME/ubuntu-optimize"

print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_header() {
    echo -e "${CYAN}${BOLD}$1${NC}"
}

# Function to check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Function to detect Ubuntu version
check_ubuntu() {
    if ! command_exists lsb_release; then
        print_error "This script is designed for Ubuntu systems."
        exit 1
    fi
    
    local ubuntu_version
    ubuntu_version=$(lsb_release -rs)
    local major_version
    major_version=$(echo "$ubuntu_version" | cut -d. -f1)
    
    if [[ $major_version -lt 18 ]]; then
        print_error "Ubuntu 18.04 LTS or newer is required. Found: $ubuntu_version"
        exit 1
    fi
    
    print_success "Ubuntu $ubuntu_version detected - compatible!"
}

# Main installation function
install_ubuntu_optimize() {
    print_header "Ubuntu Optimize Toolkit - Quick Install"
    echo ""
    
    # Check system compatibility
    print_status "Checking system compatibility..."
    check_ubuntu
    
    # Check for required tools
    print_status "Checking required tools..."
    if ! command_exists git; then
        print_status "Installing git..."
        sudo apt update && sudo apt install -y git
    fi
    
    # Remove existing installation if present
    if [[ -d "$INSTALL_DIR" ]]; then
        print_warning "Existing installation found. Removing..."
        rm -rf "$INSTALL_DIR"
    fi
    
    # Clone repository
    print_status "Downloading Ubuntu Optimize Toolkit..."
    git clone https://github.com/dipto-roy/ubuntu-optimize.git "$INSTALL_DIR"
    
    # Navigate to ubuntu-optimize directory
    if [[ -d "$INSTALL_DIR" ]]; then
        cd "$INSTALL_DIR"
    else
        print_error "Ubuntu Optimize Toolkit not found in repository"
        exit 1
    fi
    
    # Make scripts executable
    print_status "Setting up permissions..."
    chmod +x ubuntu-optimize.sh
    chmod +x scripts/*.sh
    
    # Test installation
    print_status "Testing installation..."
    ./ubuntu-optimize.sh --help > /dev/null
    
    print_success "Installation completed successfully!"
    echo ""
    print_header "Next Steps:"
    echo "1. Change to the installation directory:"
    echo "   cd $INSTALL_DIR"
    echo ""
    echo "2. Run your first optimization:"
    echo "   ./ubuntu-optimize.sh status"
    echo ""
    echo "3. For complete optimization:"
    echo "   ./ubuntu-optimize.sh full"
    echo ""
    echo "4. For system-wide installation (optional):"
    echo "   sudo cp ubuntu-optimize.sh /usr/local/bin/ubuntu-optimize"
    echo "   sudo cp ubuntu-optimize-autocomplete.sh /etc/bash_completion.d/ubuntu-optimize"
    echo ""
    echo "5. Get help anytime:"
    echo "   ./ubuntu-optimize.sh --help"
    echo ""
    print_success "Ready to optimize your Ubuntu system!"
    print_status "Repository: https://github.com/dipto-roy/ubuntu-optimize"
}

# Check if running as root
if [[ $EUID -eq 0 ]]; then
    print_error "This script should not be run as root."
    print_status "Please run as a regular user with sudo privileges."
    exit 1
fi

# Check internet connectivity
if ! ping -c 1 google.com &> /dev/null; then
    print_error "Internet connection required for installation."
    exit 1
fi

# Run installation
install_ubuntu_optimize
