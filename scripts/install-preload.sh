#!/bin/bash
#
# install-preload.sh - Preload installation and configuration script
# Part of ubuntu-optimize toolkit
#
# This script installs and configures preload daemon to improve
# application startup times by preloading frequently used libraries
#
# Author: Ubuntu Optimize Team
# Version: 1.0
# Compatible: Ubuntu LTS (18.04+)

set -e  # Exit on any error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
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

# Function to check if running as root
check_root() {
    if [[ $EUID -eq 0 ]]; then
        print_error "This script should not be run as root for safety reasons"
        exit 1
    fi
}

# Function to check available memory
check_memory() {
    local mem_gb
    mem_gb=$(free -g | awk '/^Mem:/{print $2}')
    
    if [[ $mem_gb -lt 2 ]]; then
        print_warning "Your system has less than 2GB RAM ($mem_gb GB)"
        print_warning "Preload may not be beneficial and could slow down your system"
        echo ""
        read -p "Do you want to continue anyway? (y/N): " -n 1 -r
        echo ""
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            print_status "Installation cancelled by user"
            exit 0
        fi
    else
        print_status "System has $mem_gb GB RAM - Good for preload"
    fi
}

# Function to check if preload is already installed
check_preload_installed() {
    if command -v preload &> /dev/null; then
        print_status "Preload is already installed"
        return 0
    else
        print_status "Preload is not installed"
        return 1
    fi
}

# Function to install preload
install_preload() {
    print_status "Installing preload package..."
    
    # Update package lists
    print_status "Updating package lists..."
    if sudo apt update -qq 2>/dev/null; then
        print_success "Package lists updated"
    else
        print_warning "Failed to update package lists"
    fi
    
    # Install preload
    print_status "Installing preload..."
    if sudo apt install -y preload 2>/dev/null; then
        print_success "Preload installed successfully"
    else
        print_error "Failed to install preload"
        return 1
    fi
}

# Function to configure preload
configure_preload() {
    print_status "Configuring preload..."
    
    local config_file="/etc/preload.conf"
    
    if [[ ! -f "$config_file" ]]; then
        print_error "Preload configuration file not found: $config_file"
        return 1
    fi
    
    # Backup original configuration
    if [[ ! -f "$config_file.backup" ]]; then
        if sudo cp "$config_file" "$config_file.backup"; then
            print_success "Created backup of original configuration"
        else
            print_warning "Failed to create backup"
        fi
    fi
    
    # Create optimized configuration
    print_status "Creating optimized preload configuration..."
    
    local temp_config
    temp_config=$(mktemp)
    
    cat > "$temp_config" << 'EOF'
# Preload configuration file
# Optimized for Ubuntu systems

# Model file for preload (where preload stores its learning data)
model.file = /var/lib/preload/preload.state

# Model save period in seconds (default 3600 = 1 hour)
model.save_period = 3600

# Model probability decay factor per save period
model.halflife = 168

# Minimum probability for a file to be preloaded
model.minprob = 0.05

# Number of files to preload
model.memtotal = 20

# Memory usage settings
model.memfree = 50      # Minimum free memory in MB
model.memcached = 80    # Maximum cached memory in MB

# Process monitoring settings
system.cpu = 40         # Maximum CPU usage percentage before preload pauses
system.mem = 80         # Maximum memory usage percentage

# Processes settings
processes.sort = 6      # Number of top processes to monitor
processes.fork = 30     # Fork penalty (higher = less likely to preload)
processes.exec = 20     # Exec bonus (higher = more likely to preload)

# Map files settings
model.mapprefix = /usr
model.exeprefix = /usr/bin:/bin:/usr/sbin:/sbin:/usr/games

# Cycle period in seconds
cycle.period = 20

# Logging settings
log.level = 1          # 0=none, 1=errors, 2=warnings, 3=info
log.target = /var/log/preload.log
EOF
    
    # Install the new configuration
    if sudo cp "$temp_config" "$config_file"; then
        print_success "Preload configuration updated"
    else
        print_error "Failed to update preload configuration"
        rm -f "$temp_config"
        return 1
    fi
    
    rm -f "$temp_config"
}

# Function to start and enable preload service
enable_preload_service() {
    print_status "Enabling and starting preload service..."
    
    # Enable preload service
    if sudo systemctl enable preload.service 2>/dev/null; then
        print_success "Preload service enabled"
    else
        print_warning "Failed to enable preload service"
    fi
    
    # Start preload service
    if sudo systemctl start preload.service 2>/dev/null; then
        print_success "Preload service started"
    else
        print_warning "Failed to start preload service"
        return 1
    fi
    
    # Wait a moment and check status
    sleep 2
    
    if sudo systemctl is-active preload.service &>/dev/null; then
        print_success "Preload service is running"
    else
        print_warning "Preload service may not be running properly"
        print_status "Checking service status..."
        sudo systemctl status preload.service --no-pager -l || true
    fi
}

# Function to verify installation
verify_installation() {
    print_status "Verifying preload installation..."
    
    # Check if preload binary exists
    if command -v preload &> /dev/null; then
        print_success "Preload binary is available"
    else
        print_error "Preload binary not found"
        return 1
    fi
    
    # Check if service is enabled
    if sudo systemctl is-enabled preload.service &>/dev/null; then
        print_success "Preload service is enabled"
    else
        print_warning "Preload service is not enabled"
    fi
    
    # Check if service is running
    if sudo systemctl is-active preload.service &>/dev/null; then
        print_success "Preload service is active"
    else
        print_warning "Preload service is not active"
    fi
    
    # Check configuration file
    if [[ -f "/etc/preload.conf" ]]; then
        print_success "Preload configuration file exists"
    else
        print_warning "Preload configuration file not found"
    fi
    
    # Check if preload directory exists
    if [[ -d "/var/lib/preload" ]]; then
        print_success "Preload data directory exists"
    else
        print_warning "Preload data directory not found"
    fi
}

# Function to show preload information
show_preload_info() {
    print_status "Preload Information:"
    echo ""
    print_status "What is Preload?"
    echo "  - Preload is a daemon that monitors applications you use"
    echo "  - It preloads libraries and binaries into memory"
    echo "  - This reduces application startup times"
    echo "  - It learns from your usage patterns automatically"
    echo ""
    print_status "Benefits:"
    echo "  - Faster application startup times"
    echo "  - Improved system responsiveness"
    echo "  - Automatic optimization based on usage"
    echo ""
    print_status "System Requirements:"
    echo "  - At least 2GB RAM recommended"
    echo "  - Works best with 4GB+ RAM"
    echo "  - May use 50-100MB additional memory"
    echo ""
}

# Main installation function
perform_preload_installation() {
    print_status "Starting preload installation process..."
    
    if check_preload_installed; then
        print_status "Preload is already installed"
        read -p "Do you want to reconfigure it? (y/N): " -n 1 -r
        echo ""
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            print_status "Installation cancelled by user"
            return 0
        fi
    else
        install_preload || return 1
    fi
    
    echo ""
    configure_preload || return 1
    echo ""
    enable_preload_service || return 1
    echo ""
    verify_installation
    
    echo ""
    print_success "Preload installation and configuration completed!"
    print_status "Preload will start learning your usage patterns immediately"
    print_status "You should notice improved startup times after a few hours of use"
}

# Main execution
main() {
    echo "============================================"
    echo "       Ubuntu Preload Installation Tool"
    echo "============================================"
    echo ""
    
    check_root
    
    show_preload_info
    
    # Ask for confirmation
    read -p "Do you want to install and configure preload? (y/N): " -n 1 -r
    echo ""
    
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        echo ""
        check_memory
        echo ""
        perform_preload_installation
    else
        print_status "Installation cancelled by user"
    fi
    
    echo ""
    echo "============================================"
    echo "Preload installation process finished!"
    echo "============================================"
}

# Run main function
main "$@"
