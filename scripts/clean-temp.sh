#!/bin/bash
#
# clean-temp.sh - System temporary files cleanup script
# Part of ubuntu-optimize toolkit
#
# This script safely cleans system temporary directories:
# - /tmp (system temporary files)
# - /var/tmp (persistent temporary files)
# - /var/log (old log files)
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

# Function to get directory size
get_dir_size() {
    local dir="$1"
    if [[ -d "$dir" ]]; then
        du -sh "$dir" 2>/dev/null | cut -f1 || echo "0B"
    else
        echo "0B"
    fi
}

# Function to clean /tmp directory
clean_tmp() {
    local tmp_dir="/tmp"
    
    print_status "Cleaning /tmp directory..."
    
    if [[ ! -d "$tmp_dir" ]]; then
        print_warning "/tmp directory not found"
        return 0
    fi
    
    local initial_size
    initial_size=$(get_dir_size "$tmp_dir")
    print_status "/tmp size before cleanup: $initial_size"
    
    # Clean files older than 1 day but preserve important system files
    local preserve_patterns=(
        ".X*"              # X11 sockets
        ".ICE-unix"        # ICE sockets
        ".font-unix"       # Font server sockets
        "ssh-*"            # SSH agent sockets
        "systemd-*"        # Systemd files
        "pulse-*"          # PulseAudio files
    )
    
    # Build find exclude pattern
    local exclude_args=""
    for pattern in "${preserve_patterns[@]}"; do
        exclude_args="$exclude_args -not -name '$pattern'"
    done
    
    # Clean old temporary files (older than 1 day)
    local cleaned_files=0
    while IFS= read -r -d '' file; do
        if [[ -f "$file" ]] && find "$file" -mtime +1 -type f 2>/dev/null | grep -q .; then
            if sudo rm -f "$file" 2>/dev/null; then
                ((cleaned_files++))
            fi
        fi
    done < <(find "$tmp_dir" -maxdepth 2 -type f $exclude_args -print0 2>/dev/null || true)
    
    local final_size
    final_size=$(get_dir_size "$tmp_dir")
    print_success "/tmp cleanup completed. Files cleaned: $cleaned_files, New size: $final_size"
}

# Function to clean /var/tmp directory
clean_var_tmp() {
    local var_tmp_dir="/var/tmp"
    
    print_status "Cleaning /var/tmp directory..."
    
    if [[ ! -d "$var_tmp_dir" ]]; then
        print_warning "/var/tmp directory not found"
        return 0
    fi
    
    local initial_size
    initial_size=$(get_dir_size "$var_tmp_dir")
    print_status "/var/tmp size before cleanup: $initial_size"
    
    # Clean files older than 7 days (var/tmp is for persistent temp files)
    local cleaned_files=0
    while IFS= read -r -d '' file; do
        if sudo rm -f "$file" 2>/dev/null; then
            ((cleaned_files++))
        fi
    done < <(find "$var_tmp_dir" -type f -mtime +7 -print0 2>/dev/null || true)
    
    local final_size
    final_size=$(get_dir_size "$var_tmp_dir")
    print_success "/var/tmp cleanup completed. Files cleaned: $cleaned_files, New size: $final_size"
}

# Function to clean old log files
clean_old_logs() {
    local log_dir="/var/log"
    
    print_status "Cleaning old log files..."
    
    if [[ ! -d "$log_dir" ]]; then
        print_warning "/var/log directory not found"
        return 0
    fi
    
    local initial_size
    initial_size=$(get_dir_size "$log_dir")
    print_status "/var/log size before cleanup: $initial_size"
    
    # Clean old log files (older than 30 days) but preserve recent ones
    local log_patterns=(
        "*.log.*"          # Rotated log files
        "*.gz"             # Compressed log files
        "*.old"            # Old log files
    )
    
    local cleaned_files=0
    for pattern in "${log_patterns[@]}"; do
        while IFS= read -r -d '' file; do
            if sudo rm -f "$file" 2>/dev/null; then
                ((cleaned_files++))
            fi
        done < <(find "$log_dir" -name "$pattern" -type f -mtime +30 -print0 2>/dev/null || true)
    done
    
    # Clear some specific log files but don't delete them
    local clear_logs=(
        "/var/log/kern.log"
        "/var/log/alternatives.log"
        "/var/log/dpkg.log"
    )
    
    for log_file in "${clear_logs[@]}"; do
        if [[ -f "$log_file" ]] && [[ $(stat -c%s "$log_file" 2>/dev/null || echo 0) -gt 10485760 ]]; then  # > 10MB
            if sudo truncate -s 1M "$log_file" 2>/dev/null; then
                print_status "Truncated large log file: $log_file"
            fi
        fi
    done
    
    local final_size
    final_size=$(get_dir_size "$log_dir")
    print_success "Log cleanup completed. Files cleaned: $cleaned_files, New size: $final_size"
}

# Function to clean browser temporary files
clean_browser_temp() {
    print_status "Cleaning browser temporary files..."
    
    local browser_temp_dirs=(
        "$HOME/.mozilla/firefox/*/Cache"
        "$HOME/.cache/google-chrome/Default/Cache"
        "$HOME/.cache/chromium/Default/Cache"
        "$HOME/.config/google-chrome/Default/Application Cache"
    )
    
    local cleaned_dirs=0
    for temp_dir in "${browser_temp_dirs[@]}"; do
        if [[ -d "$temp_dir" ]]; then
            if rm -rf "$temp_dir"/* 2>/dev/null; then
                print_status "Cleaned browser cache: $(dirname "$temp_dir")"
                ((cleaned_dirs++))
            fi
        fi
    done
    
    if [[ $cleaned_dirs -gt 0 ]]; then
        print_success "Browser temporary files cleaned from $cleaned_dirs locations"
    else
        print_status "No browser temporary files found to clean"
    fi
}

# Main cleanup function
perform_temp_cleanup() {
    print_status "Starting temporary files cleanup process..."
    
    # Get initial disk space
    local initial_space
    initial_space=$(df -h / | awk 'NR==2 {print $4}')
    print_status "Available disk space before cleanup: $initial_space"
    
    # Perform cleanups
    clean_tmp
    echo ""
    clean_var_tmp
    echo ""
    clean_old_logs
    echo ""
    clean_browser_temp
    
    # Get final disk space
    local final_space
    final_space=$(df -h / | awk 'NR==2 {print $4}')
    print_status "Available disk space after cleanup: $final_space"
    
    print_success "Temporary files cleanup completed successfully!"
}

# Main execution
main() {
    echo "============================================"
    echo "     Ubuntu Temporary Files Cleanup Tool"
    echo "============================================"
    echo ""
    
    check_root
    perform_temp_cleanup
    
    echo ""
    echo "============================================"
    echo "Temporary files cleanup process finished!"
    echo "============================================"
}

# Run main function
main "$@"
