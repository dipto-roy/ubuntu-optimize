#!/bin/bash
#
# clean-apt.sh - APT package management cleanup script
# Part of ubuntu-optimize toolkit
# 
# This script safely cleans APT cache, removes orphaned packages,
# and performs package database maintenance
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

# Function to check if apt is available
check_apt() {
    if ! command -v apt &> /dev/null; then
        print_error "APT package manager not found"
        exit 1
    fi
}

# Function to get disk space before cleanup
get_disk_space() {
    df -h /var/cache/apt/archives | awk 'NR==2 {print $4}'
}

# Main cleanup function
clean_apt() {
    print_status "Starting APT cleanup process..."
    
    # Get initial disk space
    local initial_space
    initial_space=$(get_disk_space)
    print_status "Available disk space before cleanup: $initial_space"
    
    # Clean APT cache
    print_status "Cleaning APT package cache..."
    if sudo apt clean 2>/dev/null; then
        print_success "APT cache cleaned successfully"
    else
        print_warning "Failed to clean APT cache (this is usually harmless)"
    fi
    
    # Remove downloaded .deb files
    print_status "Removing downloaded package files..."
    if sudo apt autoclean 2>/dev/null; then
        print_success "Downloaded package files cleaned"
    else
        print_warning "Failed to clean downloaded packages"
    fi
    
    # Remove orphaned packages
    print_status "Removing orphaned packages..."
    local orphaned_packages
    orphaned_packages=$(apt list --installed 2>/dev/null | grep -c "automatically installed" || echo "0")
    
    if [[ $orphaned_packages -gt 0 ]]; then
        if sudo apt autoremove -y 2>/dev/null; then
            print_success "Orphaned packages removed successfully"
        else
            print_warning "Failed to remove some orphaned packages"
        fi
    else
        print_status "No orphaned packages found"
    fi
    
    # Update package database
    print_status "Updating package database..."
    if sudo apt update -qq 2>/dev/null; then
        print_success "Package database updated"
    else
        print_warning "Failed to update package database"
    fi
    
    # Get final disk space
    local final_space
    final_space=$(get_disk_space)
    print_status "Available disk space after cleanup: $final_space"
    
    print_success "APT cleanup completed successfully!"
}

# Main execution
main() {
    echo "============================================"
    echo "        Ubuntu APT Cleanup Tool"
    echo "============================================"
    echo ""
    
    check_root
    check_apt
    clean_apt
    
    echo ""
    echo "============================================"
    echo "APT cleanup process finished!"
    echo "============================================"
}

# Run main function
main "$@"
