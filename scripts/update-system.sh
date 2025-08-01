#!/bin/bash
#
# update-system.sh - System update and maintenance script
# Part of ubuntu-optimize toolkit
#
# This script safely updates the Ubuntu system, including:
# - APT packages and security updates
# - Snap packages
# - Flatpak packages (if installed)
# - System maintenance tasks
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

# Function to check internet connectivity
check_internet() {
    print_status "Checking internet connectivity..."
    
    if ping -c 1 8.8.8.8 &> /dev/null || ping -c 1 1.1.1.1 &> /dev/null; then
        print_success "Internet connectivity confirmed"
        return 0
    else
        print_error "No internet connection detected"
        print_error "Please check your network connection and try again"
        return 1
    fi
}

# Function to create system backup info
create_backup_info() {
    print_status "Creating system backup information..."
    
    local backup_dir="$HOME/.ubuntu-optimize-backups"
    mkdir -p "$backup_dir"
    
    local backup_file="$backup_dir/pre-update-$(date +%Y%m%d-%H%M%S).txt"
    
    cat > "$backup_file" << EOF
# System Update Backup Information
# Created: $(date)
# Ubuntu Version: $(lsb_release -d | cut -f2)
# Kernel Version: $(uname -r)

# Installed packages before update:
$(dpkg --get-selections | grep -v deinstall)

# Repository sources:
$(cat /etc/apt/sources.list /etc/apt/sources.list.d/*.list 2>/dev/null | grep -v "^#" | grep -v "^$")

# System information:
$(uname -a)
$(free -h)
$(df -h)
EOF
    
    print_success "Backup information saved to: $backup_file"
}

# Function to update APT packages
update_apt_packages() {
    print_status "Updating APT package repositories..."
    
    # Update package lists
    if sudo apt update 2>/dev/null; then
        print_success "Package lists updated successfully"
    else
        print_error "Failed to update package lists"
        return 1
    fi
    
    # Check for available updates
    local updates_available
    updates_available=$(apt list --upgradable 2>/dev/null | wc -l)
    updates_available=$((updates_available - 1))  # Subtract header line
    
    if [[ $updates_available -eq 0 ]]; then
        print_success "System is already up to date"
        return 0
    fi
    
    print_status "$updates_available package(s) available for update"
    
    # Show major updates if any
    local major_updates
    major_updates=$(apt list --upgradable 2>/dev/null | grep -E "(linux-|ubuntu-|systemd)" | head -5 || echo "")
    
    if [[ -n "$major_updates" ]]; then
        print_warning "Major system updates detected:"
        echo "$major_updates" | while read -r line; do
            print_status "  $line"
        done
        echo ""
    fi
    
    # Perform upgrade
    print_status "Upgrading packages..."
    if sudo apt upgrade -y 2>/dev/null; then
        print_success "Package upgrade completed successfully"
    else
        print_warning "Some packages failed to upgrade"
    fi
    
    # Install security updates specifically
    print_status "Installing security updates..."
    if sudo apt install -y unattended-upgrades 2>/dev/null; then
        if sudo unattended-upgrade -d 2>/dev/null; then
            print_success "Security updates applied"
        else
            print_status "No additional security updates available"
        fi
    fi
    
    # Clean up
    print_status "Cleaning up APT cache..."
    if sudo apt autoremove -y 2>/dev/null && sudo apt autoclean 2>/dev/null; then
        print_success "APT cleanup completed"
    fi
}

# Function to update snap packages
update_snap_packages() {
    if ! command -v snap &> /dev/null; then
        print_status "Snap is not installed, skipping snap updates"
        return 0
    fi
    
    print_status "Updating Snap packages..."
    
    # List installed snaps
    local installed_snaps
    installed_snaps=$(snap list 2>/dev/null | tail -n +2 | wc -l || echo "0")
    
    if [[ $installed_snaps -eq 0 ]]; then
        print_status "No snap packages installed"
        return 0
    fi
    
    print_status "$installed_snaps snap package(s) installed"
    
    # Refresh snaps
    if sudo snap refresh 2>/dev/null; then
        print_success "Snap packages updated successfully"
    else
        print_warning "Some snap packages failed to update"
    fi
}

# Function to update flatpak packages
update_flatpak_packages() {
    if ! command -v flatpak &> /dev/null; then
        print_status "Flatpak is not installed, skipping flatpak updates"
        return 0
    fi
    
    print_status "Updating Flatpak packages..."
    
    # List installed flatpaks
    local installed_flatpaks
    installed_flatpaks=$(flatpak list 2>/dev/null | wc -l || echo "0")
    
    if [[ $installed_flatpaks -eq 0 ]]; then
        print_status "No flatpak packages installed"
        return 0
    fi
    
    print_status "$installed_flatpaks flatpak package(s) installed"
    
    # Update flatpaks
    if flatpak update -y 2>/dev/null; then
        print_success "Flatpak packages updated successfully"
    else
        print_warning "Some flatpak packages failed to update"
    fi
}

# Function to update firmware
update_firmware() {
    if ! command -v fwupdmgr &> /dev/null; then
        print_status "fwupd is not available, skipping firmware updates"
        return 0
    fi
    
    print_status "Checking for firmware updates..."
    
    # Refresh firmware metadata
    if fwupdmgr refresh --force 2>/dev/null; then
        print_status "Firmware metadata refreshed"
    else
        print_warning "Failed to refresh firmware metadata"
        return 0
    fi
    
    # Check for available firmware updates
    local firmware_updates
    firmware_updates=$(fwupdmgr get-updates 2>/dev/null | grep -c "Update available" || echo "0")
    
    if [[ $firmware_updates -eq 0 ]]; then
        print_success "No firmware updates available"
        return 0
    fi
    
    print_warning "$firmware_updates firmware update(s) available"
    print_warning "Firmware updates can be risky and may require a reboot"
    echo ""
    read -p "Do you want to install firmware updates? (y/N): " -n 1 -r
    echo ""
    
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        if fwupdmgr update -y 2>/dev/null; then
            print_success "Firmware updates completed"
        else
            print_warning "Some firmware updates failed"
        fi
    else
        print_status "Firmware updates skipped by user"
    fi
}

# Function to check for distribution upgrades
check_dist_upgrade() {
    print_status "Checking for distribution upgrades..."
    
    if command -v do-release-upgrade &> /dev/null; then
        # Check if new release is available
        local upgrade_check
        upgrade_check=$(do-release-upgrade -c 2>/dev/null || echo "")
        
        if echo "$upgrade_check" | grep -q "New release"; then
            print_warning "A new Ubuntu release is available"
            echo "$upgrade_check"
            print_warning "Distribution upgrades should be done carefully"
            print_status "Run 'sudo do-release-upgrade' manually when ready"
        else
            print_success "No distribution upgrades available"
        fi
    else
        print_status "Distribution upgrade tool not available"
    fi
}

# Function to perform system maintenance
perform_maintenance() {
    print_status "Performing system maintenance tasks..."
    
    # Update locate database
    if command -v updatedb &> /dev/null; then
        print_status "Updating locate database..."
        if sudo updatedb 2>/dev/null; then
            print_success "Locate database updated"
        else
            print_warning "Failed to update locate database"
        fi
    fi
    
    # Update man pages
    if command -v mandb &> /dev/null; then
        print_status "Updating man page database..."
        if sudo mandb --quiet 2>/dev/null; then
            print_success "Man page database updated"
        else
            print_warning "Failed to update man page database"
        fi
    fi
    
    # Check for broken packages
    print_status "Checking for broken packages..."
    local broken_packages
    broken_packages=$(dpkg --audit 2>/dev/null | wc -l || echo "0")
    
    if [[ $broken_packages -eq 0 ]]; then
        print_success "No broken packages found"
    else
        print_warning "$broken_packages broken package(s) found"
        print_status "Running package repair..."
        if sudo apt --fix-broken install -y 2>/dev/null; then
            print_success "Package repair completed"
        else
            print_warning "Package repair failed - manual intervention may be required"
        fi
    fi
    
    # Check disk space
    print_status "Checking disk space..."
    local root_usage
    root_usage=$(df / | awk 'NR==2 {print $5}' | tr -d '%')
    
    if [[ $root_usage -gt 90 ]]; then
        print_warning "Root filesystem is ${root_usage}% full"
        print_status "Consider running disk cleanup tools"
    else
        print_success "Disk space usage is healthy (${root_usage}% used)"
    fi
}

# Function to check if reboot is required
check_reboot_required() {
    print_status "Checking if system reboot is required..."
    
    if [[ -f /var/run/reboot-required ]]; then
        print_warning "System reboot is required!"
        
        if [[ -f /var/run/reboot-required.pkgs ]]; then
            local packages
            packages=$(cat /var/run/reboot-required.pkgs | tr '\n' ' ')
            print_status "Packages requiring reboot: $packages"
        fi
        
        echo ""
        read -p "Do you want to reboot now? (y/N): " -n 1 -r
        echo ""
        
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            print_status "Rebooting system in 10 seconds..."
            print_warning "Save your work now!"
            sleep 10
            sudo reboot
        else
            print_warning "Please reboot your system when convenient"
        fi
    else
        print_success "No reboot required"
    fi
}

# Function to show update summary
show_update_summary() {
    print_status "Update Summary:"
    
    # Show current system info
    local ubuntu_version
    local kernel_version
    ubuntu_version=$(lsb_release -d | cut -f2)
    kernel_version=$(uname -r)
    
    print_status "Ubuntu Version: $ubuntu_version"
    print_status "Kernel Version: $kernel_version"
    
    # Show last update time
    local last_apt_update
    last_apt_update=$(stat -c %y /var/cache/apt/pkgcache.bin 2>/dev/null | cut -d' ' -f1 || echo "Unknown")
    print_status "Last APT update: $last_apt_update"
    
    # Show system uptime
    local uptime_info
    uptime_info=$(uptime -p 2>/dev/null || uptime)
    print_status "System uptime: $uptime_info"
}

# Main update function
perform_system_update() {
    print_status "Starting comprehensive system update..."
    
    # Create backup info
    create_backup_info
    echo ""
    
    # Update APT packages
    update_apt_packages
    echo ""
    
    # Update snap packages
    update_snap_packages
    echo ""
    
    # Update flatpak packages
    update_flatpak_packages
    echo ""
    
    # Update firmware
    update_firmware
    echo ""
    
    # Check for distribution upgrades
    check_dist_upgrade
    echo ""
    
    # Perform maintenance
    perform_maintenance
    echo ""
    
    # Show summary
    show_update_summary
    echo ""
    
    # Check if reboot is required
    check_reboot_required
    
    print_success "System update completed successfully!"
}

# Main execution
main() {
    echo "============================================"
    echo "       Ubuntu System Update Tool"
    echo "============================================"
    echo ""
    
    check_root
    
    if ! check_internet; then
        exit 1
    fi
    
    echo ""
    print_warning "This will update your entire system including:"
    print_status "- APT packages and security updates"
    print_status "- Snap packages"
    print_status "- Flatpak packages (if installed)"
    print_status "- Firmware (with confirmation)"
    print_status "- System maintenance tasks"
    echo ""
    read -p "Do you want to continue? (y/N): " -n 1 -r
    echo ""
    
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        echo ""
        perform_system_update
    else
        print_status "System update cancelled by user"
    fi
    
    echo ""
    echo "============================================"
    echo "System update process finished!"
    echo "============================================"
}

# Run main function
main "$@"
