#!/bin/bash
#
# clean-snap.sh - Snap package cleanup script
# Part of ubuntu-optimize toolkit
#
# This script safely cleans snap package cache and removes old revisions
# while keeping the current active revision
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

# Function to check if snap is available
check_snap() {
    if ! command -v snap &> /dev/null; then
        print_warning "Snap package manager not found, skipping snap cleanup"
        return 1
    fi
    return 0
}

# Function to check if running as root
check_root() {
    if [[ $EUID -eq 0 ]]; then
        print_error "This script should not be run as root for safety reasons"
        exit 1
    fi
}

# Function to get snap directory size
get_snap_size() {
    local snap_dir="/var/lib/snapd/snaps"
    if [[ -d "$snap_dir" ]]; then
        du -sh "$snap_dir" 2>/dev/null | cut -f1 || echo "0B"
    else
        echo "0B"
    fi
}

# Function to clean old snap revisions
clean_old_revisions() {
    print_status "Checking for old snap revisions..."
    
    # Get list of all installed snaps
    local snaps
    snaps=$(snap list --all | awk '/disabled/{print $1, $3}' 2>/dev/null || echo "")
    
    if [[ -z "$snaps" ]]; then
        print_status "No old snap revisions found"
        return 0
    fi
    
    local cleaned_count=0
    
    while IFS=' ' read -r snap_name revision; do
        if [[ -n "$snap_name" && -n "$revision" ]]; then
            print_status "Removing old revision of $snap_name (revision $revision)..."
            if sudo snap remove "$snap_name" --revision="$revision" 2>/dev/null; then
                print_success "Removed $snap_name revision $revision"
                ((cleaned_count++))
            else
                print_warning "Failed to remove $snap_name revision $revision"
            fi
        fi
    done <<< "$snaps"
    
    if [[ $cleaned_count -gt 0 ]]; then
        print_success "Cleaned $cleaned_count old snap revisions"
    else
        print_status "No snap revisions were cleaned"
    fi
}

# Function to clean snap cache
clean_snap_cache() {
    print_status "Cleaning snap cache..."
    
    local cache_dirs=(
        "/var/lib/snapd/cache"
        "/var/cache/snapd"
        "$HOME/snap/*/common/.cache"
    )
    
    for cache_dir in "${cache_dirs[@]}"; do
        if [[ -d "$cache_dir" ]]; then
            print_status "Cleaning cache directory: $cache_dir"
            if sudo find "$cache_dir" -type f -delete 2>/dev/null; then
                print_success "Cleaned: $cache_dir"
            else
                print_warning "Failed to clean: $cache_dir"
            fi
        fi
    done
}

# Function to refresh snap store cache
refresh_snap_cache() {
    print_status "Refreshing snap store cache..."
    
    if snap refresh --list &>/dev/null; then
        print_success "Snap cache refreshed"
    else
        print_warning "Failed to refresh snap cache"
    fi
}

# Main cleanup function
perform_snap_cleanup() {
    print_status "Starting snap cleanup process..."
    
    # Get initial snap directory size
    local initial_size
    initial_size=$(get_snap_size)
    print_status "Snap directory size before cleanup: $initial_size"
    
    # Perform cleanups
    clean_old_revisions
    echo ""
    clean_snap_cache
    echo ""
    refresh_snap_cache
    
    # Get final snap directory size
    local final_size
    final_size=$(get_snap_size)
    print_status "Snap directory size after cleanup: $final_size"
    
    print_success "Snap cleanup completed successfully!"
}

# Main execution
main() {
    echo "============================================"
    echo "        Ubuntu Snap Cleanup Tool"
    echo "============================================"
    echo ""
    
    check_root
    
    if check_snap; then
        perform_snap_cleanup
    else
        print_status "Snap is not installed, nothing to clean"
    fi
    
    echo ""
    echo "============================================"
    echo "Snap cleanup process finished!"
    echo "============================================"
}

# Run main function
main "$@"
