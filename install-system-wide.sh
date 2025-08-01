#!/bin/bash
#
# install-system-wide.sh - System-wide installation script
# 
# This script properly installs the Ubuntu Optimize Toolkit system-wide

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

# Check if running as root
if [[ $EUID -eq 0 ]]; then
    print_error "This script should not be run as root"
    print_error "Run as a regular user - it will ask for sudo when needed"
    exit 1
fi

# Check if we're in the right directory
if [[ ! -f "ubuntu-optimize.sh" ]] || [[ ! -d "scripts" ]]; then
    print_error "Please run this script from the ubuntu-optimize directory"
    print_error "Expected: ubuntu-optimize.sh and scripts/ directory"
    exit 1
fi

print_header "Ubuntu Optimize Toolkit - System-wide Installation"
echo ""

# Step 1: Create installation directory
INSTALL_DIR="/opt/ubuntu-optimize"
print_status "Creating installation directory: $INSTALL_DIR"

if sudo mkdir -p "$INSTALL_DIR"; then
    print_success "Installation directory created"
else
    print_error "Failed to create installation directory"
    exit 1
fi

# Step 2: Copy all files
print_status "Copying toolkit files..."

if sudo cp -r * "$INSTALL_DIR/"; then
    print_success "Files copied to $INSTALL_DIR"
else
    print_error "Failed to copy files"
    exit 1
fi

# Step 3: Set permissions
print_status "Setting permissions..."
sudo chmod +x "$INSTALL_DIR"/*.sh
sudo chmod +x "$INSTALL_DIR"/scripts/*.sh
sudo chown -R root:root "$INSTALL_DIR"
sudo chmod -R 755 "$INSTALL_DIR"
print_success "Permissions set"

# Step 4: Create wrapper script in /usr/local/bin
print_status "Creating system-wide command..."

cat << 'EOF' | sudo tee /usr/local/bin/ubuntu-optimize > /dev/null
#!/bin/bash
# Ubuntu Optimize Toolkit - System-wide wrapper script
exec /opt/ubuntu-optimize/ubuntu-optimize.sh "$@"
EOF

sudo chmod +x /usr/local/bin/ubuntu-optimize
print_success "System-wide command created: /usr/local/bin/ubuntu-optimize"

# Step 5: Install autocomplete
print_status "Installing bash autocomplete..."
sudo cp ubuntu-optimize-autocomplete.sh /etc/bash_completion.d/ubuntu-optimize
print_success "Autocomplete installed"

# Step 6: Update autocomplete script for system command
print_status "Updating autocomplete for system-wide usage..."
sudo sed -i 's/ubuntu-optimize\.sh/ubuntu-optimize/g' /etc/bash_completion.d/ubuntu-optimize
print_success "Autocomplete updated"

echo ""
print_header "Installation Complete! 🎉"
echo ""
print_success "✅ Ubuntu Optimize Toolkit installed system-wide"
print_success "✅ Available as 'ubuntu-optimize' command"
print_success "✅ Bash autocomplete enabled"
echo ""
print_status "Test the installation:"
echo "  ${CYAN}ubuntu-optimize status${NC}"
echo "  ${CYAN}ubuntu-optimize list${NC}"
echo "  ${CYAN}ubuntu-optimize --help${NC}"
echo ""
print_warning "💡 Restart your terminal or run 'source ~/.bashrc' for autocomplete"
echo ""
print_status "Files installed to: $INSTALL_DIR"
print_status "Command available at: /usr/local/bin/ubuntu-optimize"
print_status "Autocomplete at: /etc/bash_completion.d/ubuntu-optimize"

# Step 7: Test the installation
echo ""
print_status "Testing installation..."
if ubuntu-optimize --help > /dev/null 2>&1; then
    print_success "✅ System-wide installation is working!"
else
    print_error "❌ Installation test failed"
    exit 1
fi
