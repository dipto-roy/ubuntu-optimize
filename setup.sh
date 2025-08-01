#!/bin/bash
#
# setup.sh - Complete setup script for Ubuntu Optimize Toolkit
# 
# This script sets up the toolkit for both local and system-wide use
# Usage: bash setup.sh

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m' # No Color

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

# Check if we're in the right directory
if [[ ! -f "ubuntu-optimize.sh" ]] || [[ ! -f "ubuntu-optimize-autocomplete.sh" ]]; then
    print_error "Please run this script from the ubuntu-optimize directory"
    print_error "Expected files: ubuntu-optimize.sh, ubuntu-optimize-autocomplete.sh"
    exit 1
fi

print_header "Ubuntu Optimize Toolkit - Setup Script"
echo ""

# Step 1: Make scripts executable
print_status "Making scripts executable..."
chmod +x ubuntu-optimize.sh ubuntu-optimize-autocomplete.sh scripts/*.sh install.sh 2>/dev/null || true
print_success "Scripts are now executable"

# Step 2: Test the main script
print_status "Testing main script..."
if ./ubuntu-optimize.sh --help > /dev/null 2>&1; then
    print_success "Main script is working correctly"
else
    print_error "Main script has issues"
    exit 1
fi

# Step 3: Set up autocomplete for current session
print_status "Setting up autocomplete for current session..."
source ubuntu-optimize-autocomplete.sh 2>/dev/null || true
print_success "Autocomplete loaded for current session"

# Step 4: Ask for system-wide installation
echo ""
print_header "System-wide Installation (Optional)"
print_status "This will install 'ubuntu-optimize' command globally"
print_status "You'll be able to run 'ubuntu-optimize' from anywhere"
echo ""
read -p "Install system-wide? (y/N): " -n 1 -r
echo ""

if [[ $REPLY =~ ^[Yy]$ ]]; then
    print_status "Installing system-wide..."
    
    if sudo cp ubuntu-optimize.sh /usr/local/bin/ubuntu-optimize; then
        print_success "Main script installed to /usr/local/bin/ubuntu-optimize"
    else
        print_error "Failed to install main script"
        exit 1
    fi
    
    if sudo cp ubuntu-optimize-autocomplete.sh /etc/bash_completion.d/ubuntu-optimize; then
        print_success "Autocomplete installed to /etc/bash_completion.d/ubuntu-optimize"
    else
        print_warning "Failed to install autocomplete (non-critical)"
    fi
    
    # Load autocomplete
    source /etc/bash_completion.d/ubuntu-optimize 2>/dev/null || true
    print_success "You can now use 'ubuntu-optimize' from anywhere!"
    
    GLOBAL_INSTALL=true
else
    print_status "Skipping system-wide installation"
    GLOBAL_INSTALL=false
fi

# Step 5: Add to .bashrc for persistent autocomplete
echo ""
print_status "Setting up persistent autocomplete..."

if [[ $GLOBAL_INSTALL == true ]]; then
    # For global installation, just ensure bash completion is enabled
    if ! grep -q "/etc/bash_completion" ~/.bashrc 2>/dev/null; then
        echo "" >> ~/.bashrc
        echo "# Enable bash completion" >> ~/.bashrc
        echo "if [ -f /etc/bash_completion ]; then" >> ~/.bashrc
        echo "    . /etc/bash_completion" >> ~/.bashrc
        echo "fi" >> ~/.bashrc
        print_success "Added bash completion to ~/.bashrc"
    fi
else
    # For local installation, add specific autocomplete
    if ! grep -q "ubuntu-optimize-autocomplete.sh" ~/.bashrc 2>/dev/null; then
        echo "" >> ~/.bashrc
        echo "# Ubuntu Optimize Toolkit autocomplete" >> ~/.bashrc
        echo "if [ -f \"$PWD/ubuntu-optimize-autocomplete.sh\" ]; then" >> ~/.bashrc
        echo "    source \"$PWD/ubuntu-optimize-autocomplete.sh\"" >> ~/.bashrc
        echo "fi" >> ~/.bashrc
        print_success "Added local autocomplete to ~/.bashrc"
    fi
fi

# Step 6: Show completion info
echo ""
print_header "Setup Complete! 🎉"
echo ""

if [[ $GLOBAL_INSTALL == true ]]; then
    print_success "✅ System-wide installation complete"
    echo "You can now run these commands from anywhere:"
    echo "  ${CYAN}ubuntu-optimize status${NC}"
    echo "  ${CYAN}ubuntu-optimize list${NC}"
    echo "  ${CYAN}ubuntu-optimize clean-cache${NC}"
    echo "  ${CYAN}ubuntu-optimize full${NC}"
else
    print_success "✅ Local installation complete"
    echo "Run these commands from this directory:"
    echo "  ${CYAN}./ubuntu-optimize.sh status${NC}"
    echo "  ${CYAN}./ubuntu-optimize.sh list${NC}"
    echo "  ${CYAN}./ubuntu-optimize.sh clean-cache${NC}"
    echo "  ${CYAN}./ubuntu-optimize.sh full${NC}"
fi

echo ""
print_header "Available Commands:"
echo "Main commands:"
echo "  ${CYAN}full${NC}              Complete system optimization"
echo "  ${CYAN}update${NC}            Update system packages"
echo "  ${CYAN}clean-apt${NC}         Clean APT package cache"
echo "  ${CYAN}clean-cache${NC}       Clean user cache files"
echo "  ${CYAN}clean-snap${NC}        Clean snap package cache"
echo "  ${CYAN}clean-temp${NC}        Clean temporary files"
echo "  ${CYAN}ram-clean${NC}         Optimize RAM usage"
echo "  ${CYAN}limit-logs${NC}        Manage system logs"
echo "  ${CYAN}trim-ssd${NC}          Optimize SSD performance"
echo "  ${CYAN}disable-tracker${NC}   Disable GNOME tracker"
echo "  ${CYAN}install-preload${NC}   Install preload for faster boot"
echo "  ${CYAN}status${NC}            Show system status"
echo "  ${CYAN}list${NC}              List all commands"
echo "  ${CYAN}version${NC}           Show version"
echo "  ${CYAN}help${NC}              Show help"

echo ""
echo "Options (work with any command):"
echo "  ${CYAN}-v, --verbose${NC}     Enable verbose output"
echo "  ${CYAN}-q, --quiet${NC}       Suppress non-error output"
echo "  ${CYAN}-y, --yes${NC}         Auto-answer yes to prompts"
echo "  ${CYAN}-h, --help${NC}        Show command help"

echo ""
print_header "Autocomplete Usage:"
echo "Press TAB after typing any command to see available options:"
if [[ $GLOBAL_INSTALL == true ]]; then
    echo "  ${CYAN}ubuntu-optimize <TAB><TAB>${NC}     # Shows all commands"
    echo "  ${CYAN}ubuntu-optimize cl<TAB>${NC}        # Completes to clean-* commands"
    echo "  ${CYAN}ubuntu-optimize full --<TAB>${NC}   # Shows available options"
else
    echo "  ${CYAN}./ubuntu-optimize.sh <TAB><TAB>${NC}     # Shows all commands"
    echo "  ${CYAN}./ubuntu-optimize.sh cl<TAB>${NC}        # Completes to clean-* commands"
    echo "  ${CYAN}./ubuntu-optimize.sh full --<TAB>${NC}   # Shows available options"
fi

echo ""
print_warning "💡 Restart your terminal or run 'source ~/.bashrc' for autocomplete to work in new sessions"

echo ""
print_success "🚀 Ready to optimize your Ubuntu system!"
print_status "Repository: https://github.com/dipto-roy/ubuntu-optimize"
