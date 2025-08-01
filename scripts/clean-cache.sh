#!/bin/bash
#
# clean-cache.sh - User cache cleanup script
# Part of ubuntu-optimize toolkit
#
# This script safely cleans user cache directories including:
# - ~/.cache/* (application cache)
# - ~/.cache/thumbnails/* (thumbnail cache)
# - ~/.local/share/Trash/* (trash/recycle bin)
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

# Function to get directory size in human readable format
get_dir_size() {
    local dir="$1"
    if [[ -d "$dir" ]]; then
        du -sh "$dir" 2>/dev/null | cut -f1 || echo "0B"
    else
        echo "0B"
    fi
}

# Function to clean cache directory
clean_cache_dir() {
    local cache_dir="$HOME/.cache"
    
    if [[ ! -d "$cache_dir" ]]; then
        print_status "Cache directory does not exist: $cache_dir"
        return 0
    fi
    
    local initial_size
    initial_size=$(get_dir_size "$cache_dir")
    print_status "Cache directory size before cleanup: $initial_size"
    
    # Clean general cache but preserve important directories
    print_status "Cleaning application cache..."
    
    # List of directories to preserve (add more as needed)
    local preserve_dirs=(
        "fontconfig"
        "mesa_shader_cache"
        "nvidia"
    )
    
    # Clean cache contents while preserving important directories
    find "$cache_dir" -mindepth 1 -maxdepth 1 -type d | while read -r dir; do
        local dirname
        dirname=$(basename "$dir")
        local preserve=false
        
        for preserve_dir in "${preserve_dirs[@]}"; do
            if [[ "$dirname" == "$preserve_dir" ]]; then
                preserve=true
                break
            fi
        done
        
        if [[ "$preserve" == false ]]; then
            if rm -rf "$dir" 2>/dev/null; then
                print_status "Cleaned: $dirname"
            else
                print_warning "Failed to clean: $dirname (may be in use)"
            fi
        else
            print_status "Preserved: $dirname"
        fi
    done
    
    # Clean cache files (not directories)
    find "$cache_dir" -maxdepth 1 -type f -delete 2>/dev/null || true
    
    local final_size
    final_size=$(get_dir_size "$cache_dir")
    print_success "Cache cleanup completed. New size: $final_size"
}

# Function to clean thumbnail cache
clean_thumbnails() {
    local thumb_dir="$HOME/.cache/thumbnails"
    
    if [[ ! -d "$thumb_dir" ]]; then
        print_status "Thumbnail cache directory does not exist"
        return 0
    fi
    
    local initial_size
    initial_size=$(get_dir_size "$thumb_dir")
    print_status "Thumbnail cache size before cleanup: $initial_size"
    
    if rm -rf "$thumb_dir"/* 2>/dev/null; then
        print_success "Thumbnail cache cleaned successfully"
    else
        print_warning "Some thumbnail files could not be removed (may be in use)"
    fi
    
    local final_size
    final_size=$(get_dir_size "$thumb_dir")
    print_status "Thumbnail cache size after cleanup: $final_size"
}

# Function to clean trash
clean_trash() {
    local trash_dir="$HOME/.local/share/Trash"
    
    if [[ ! -d "$trash_dir" ]]; then
        print_status "Trash directory does not exist"
        return 0
    fi
    
    local initial_size
    initial_size=$(get_dir_size "$trash_dir")
    print_status "Trash size before cleanup: $initial_size"
    
    # Clean trash files
    if [[ -d "$trash_dir/files" ]]; then
        if rm -rf "$trash_dir/files"/* 2>/dev/null; then
            print_success "Trash files cleaned"
        else
            print_warning "Some trash files could not be removed"
        fi
    fi
    
    # Clean trash info
    if [[ -d "$trash_dir/info" ]]; then
        if rm -rf "$trash_dir/info"/* 2>/dev/null; then
            print_success "Trash metadata cleaned"
        else
            print_warning "Some trash metadata could not be removed"
        fi
    fi
    
    local final_size
    final_size=$(get_dir_size "$trash_dir")
    print_status "Trash size after cleanup: $final_size"
}

# Function to clean temporary files in home directory
clean_temp_files() {
    print_status "Cleaning temporary files in home directory..."
    
    # Clean common temporary file patterns
    local temp_patterns=(
        "$HOME/.*~"           # Backup files
        "$HOME/.*.swp"        # Vim swap files
        "$HOME/.*.tmp"        # Temporary files
        "$HOME/core"          # Core dumps
    )
    
    for pattern in "${temp_patterns[@]}"; do
        find "$HOME" -maxdepth 1 -name "$(basename "$pattern")" -type f -delete 2>/dev/null || true
    done
    
    print_success "Temporary files cleaned"
}

# Main cleanup function
perform_cache_cleanup() {
    print_status "Starting cache cleanup process..."
    
    # Get initial disk space
    local initial_space
    initial_space=$(df -h "$HOME" | awk 'NR==2 {print $4}')
    print_status "Available disk space before cleanup: $initial_space"
    
    # Perform cleanups
    clean_cache_dir
    echo ""
    clean_thumbnails
    echo ""
    clean_trash
    echo ""
    clean_temp_files
    
    # Get final disk space
    local final_space
    final_space=$(df -h "$HOME" | awk 'NR==2 {print $4}')
    print_status "Available disk space after cleanup: $final_space"
    
    print_success "Cache cleanup completed successfully!"
}

# Main execution
main() {
    echo "============================================"
    echo "        Ubuntu Cache Cleanup Tool"
    echo "============================================"
    echo ""
    
    perform_cache_cleanup
    
    echo ""
    echo "============================================"
    echo "Cache cleanup process finished!"
    echo "============================================"
}

# Run main function
main "$@"
