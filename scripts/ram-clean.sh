#!/bin/bash
#
# ram-clean.sh - Memory optimization and cleanup script
# Part of ubuntu-optimize toolkit
#
# This script safely cleans system memory by clearing caches,
# dropping unused memory pages, and optimizing memory usage
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

# Function to get memory information
get_memory_info() {
    local info_type="$1"
    case "$info_type" in
        "total")
            free -h | awk '/^Mem:/{print $2}'
            ;;
        "used")
            free -h | awk '/^Mem:/{print $3}'
            ;;
        "free")
            free -h | awk '/^Mem:/{print $4}'
            ;;
        "available")
            free -h | awk '/^Mem:/{print $7}'
            ;;
        "cached")
            free -h | awk '/^Mem:/{print $6}'
            ;;
        "swap_used")
            free -h | awk '/^Swap:/{print $3}'
            ;;
        "swap_free")
            free -h | awk '/^Swap:/{print $4}'
            ;;
        *)
            echo "Unknown"
            ;;
    esac
}

# Function to display memory status
show_memory_status() {
    print_status "Current memory status:"
    echo "  Total Memory:     $(get_memory_info total)"
    echo "  Used Memory:      $(get_memory_info used)"
    echo "  Free Memory:      $(get_memory_info free)"
    echo "  Available Memory: $(get_memory_info available)"
    echo "  Cached Memory:    $(get_memory_info cached)"
    echo "  Swap Used:        $(get_memory_info swap_used)"
    echo "  Swap Free:        $(get_memory_info swap_free)"
}

# Function to clear page cache
clear_page_cache() {
    print_status "Clearing page cache..."
    
    # Sync filesystem buffers first
    if sudo sync; then
        print_status "Filesystem buffers synchronized"
    else
        print_warning "Failed to sync filesystem buffers"
    fi
    
    # Clear page cache (1)
    if echo 1 | sudo tee /proc/sys/vm/drop_caches > /dev/null 2>&1; then
        print_success "Page cache cleared"
    else
        print_warning "Failed to clear page cache"
    fi
    
    sleep 1
}

# Function to clear dentries and inodes
clear_dentries_inodes() {
    print_status "Clearing dentries and inodes..."
    
    # Clear dentries and inodes (2)
    if echo 2 | sudo tee /proc/sys/vm/drop_caches > /dev/null 2>&1; then
        print_success "Dentries and inodes cleared"
    else
        print_warning "Failed to clear dentries and inodes"
    fi
    
    sleep 1
}

# Function to clear all caches
clear_all_caches() {
    print_status "Clearing all kernel caches..."
    
    # Clear page cache, dentries and inodes (3)
    if echo 3 | sudo tee /proc/sys/vm/drop_caches > /dev/null 2>&1; then
        print_success "All kernel caches cleared"
    else
        print_warning "Failed to clear all caches"
    fi
    
    sleep 1
}

# Function to optimize swap usage
optimize_swap() {
    print_status "Optimizing swap usage..."
    
    local swap_used
    swap_used=$(free | awk '/^Swap:/{print $3}')
    
    if [[ $swap_used -eq 0 ]]; then
        print_status "No swap is currently in use"
        return 0
    fi
    
    local swap_used_mb
    swap_used_mb=$((swap_used / 1024))
    
    if [[ $swap_used_mb -gt 100 ]]; then
        print_status "Swap usage detected (${swap_used_mb}MB), attempting to optimize..."
        
        # Try to swap off and on to consolidate memory
        local swap_devices
        swap_devices=$(swapon --show=NAME --noheadings 2>/dev/null || echo "")
        
        if [[ -n "$swap_devices" ]]; then
            print_warning "This will temporarily disable swap to consolidate memory"
            read -p "Continue? (y/N): " -n 1 -r
            echo ""
            
            if [[ $REPLY =~ ^[Yy]$ ]]; then
                # Check if we have enough free memory
                local available_mb
                available_mb=$(free -m | awk '/^Mem:/{print $7}')
                
                if [[ $available_mb -gt $((swap_used_mb + 200)) ]]; then
                    print_status "Sufficient memory available, optimizing swap..."
                    
                    if sudo swapoff -a && sudo swapon -a; then
                        print_success "Swap optimized successfully"
                    else
                        print_warning "Failed to optimize swap"
                    fi
                else
                    print_warning "Insufficient memory to safely optimize swap"
                    print_status "Available: ${available_mb}MB, Needed: $((swap_used_mb + 200))MB"
                fi
            else
                print_status "Swap optimization skipped by user"
            fi
        else
            print_status "No active swap devices found"
        fi
    else
        print_status "Swap usage is minimal (${swap_used_mb}MB), no optimization needed"
    fi
}

# Function to compact memory
compact_memory() {
    print_status "Compacting memory..."
    
    # Trigger memory compaction
    if echo 1 | sudo tee /proc/sys/vm/compact_memory > /dev/null 2>&1; then
        print_success "Memory compaction triggered"
    else
        print_warning "Failed to trigger memory compaction (may not be supported)"
    fi
    
    sleep 2
}

# Function to clean tmpfs
clean_tmpfs() {
    print_status "Cleaning tmpfs filesystems..."
    
    local tmpfs_mounts
    tmpfs_mounts=$(mount | grep tmpfs | awk '{print $3}' || echo "")
    
    local cleaned_count=0
    
    while IFS= read -r mount_point; do
        if [[ -n "$mount_point" ]] && [[ "$mount_point" != "/dev" ]] && [[ "$mount_point" != "/dev/shm" ]] && [[ "$mount_point" != "/run" ]]; then
            # Only clean user-writable tmpfs mounts
            if [[ -w "$mount_point" ]]; then
                local size_before
                size_before=$(du -sh "$mount_point" 2>/dev/null | cut -f1 || echo "0B")
                
                # Clean temporary files in tmpfs
                find "$mount_point" -type f -name "*.tmp" -o -name "core" -o -name "*.core" 2>/dev/null | while read -r file; do
                    if rm -f "$file" 2>/dev/null; then
                        ((cleaned_count++))
                    fi
                done
                
                local size_after
                size_after=$(du -sh "$mount_point" 2>/dev/null | cut -f1 || echo "0B")
                
                if [[ "$size_before" != "$size_after" ]]; then
                    print_success "Cleaned tmpfs: $mount_point ($size_before -> $size_after)"
                fi
            fi
        fi
    done <<< "$tmpfs_mounts"
    
    if [[ $cleaned_count -gt 0 ]]; then
        print_success "Cleaned $cleaned_count temporary files from tmpfs"
    else
        print_status "No temporary files found in tmpfs to clean"
    fi
}

# Function to optimize memory settings
optimize_memory_settings() {
    print_status "Optimizing memory settings..."
    
    local sysctl_conf="/etc/sysctl.d/99-ubuntu-optimize-memory.conf"
    
    # Create optimized memory configuration
    local temp_conf
    temp_conf=$(mktemp)
    
    cat > "$temp_conf" << 'EOF'
# Ubuntu Optimize - Memory optimization settings

# Virtual memory settings
vm.swappiness=10
vm.vfs_cache_pressure=50
vm.dirty_background_ratio=5
vm.dirty_ratio=10

# Memory overcommit settings
vm.overcommit_memory=1
vm.overcommit_ratio=80

# Kernel memory settings
kernel.shmmax=268435456
kernel.shmall=2097152

# Network memory settings
net.core.rmem_default=212992
net.core.rmem_max=16777216
net.core.wmem_default=212992
net.core.wmem_max=16777216
EOF
    
    if sudo cp "$temp_conf" "$sysctl_conf"; then
        print_success "Memory optimization settings created"
        
        # Apply the settings
        if sudo sysctl -p "$sysctl_conf" 2>/dev/null; then
            print_success "Memory optimization settings applied"
        else
            print_warning "Failed to apply memory settings immediately"
        fi
    else
        print_warning "Failed to create memory optimization settings"
    fi
    
    rm -f "$temp_conf"
}

# Function to kill memory-hungry processes (with user confirmation)
suggest_process_cleanup() {
    print_status "Analyzing memory usage by processes..."
    
    # Find top 5 memory-consuming processes
    local top_processes
    top_processes=$(ps aux --sort=-%mem | head -6 | tail -5)
    
    if [[ -n "$top_processes" ]]; then
        print_status "Top memory-consuming processes:"
        echo "$top_processes" | while read -r line; do
            local process_name
            local mem_usage
            process_name=$(echo "$line" | awk '{print $11}')
            mem_usage=$(echo "$line" | awk '{print $4}')
            echo "  $process_name: ${mem_usage}% memory"
        done
        
        echo ""
        print_warning "Consider closing unnecessary applications to free memory"
        print_status "You can use 'htop' or 'top' to monitor and manage processes"
    else
        print_status "Unable to analyze process memory usage"
    fi
}

# Main memory cleanup function
perform_ram_cleanup() {
    print_status "Starting RAM cleanup process..."
    
    # Show initial memory status
    show_memory_status
    echo ""
    
    # Perform cleanup operations
    clear_page_cache
    sleep 1
    
    clear_dentries_inodes
    sleep 1
    
    clear_all_caches
    sleep 1
    
    clean_tmpfs
    echo ""
    
    compact_memory
    echo ""
    
    optimize_swap
    echo ""
    
    optimize_memory_settings
    echo ""
    
    suggest_process_cleanup
    echo ""
    
    # Show final memory status
    print_status "Memory status after cleanup:"
    show_memory_status
    
    print_success "RAM cleanup completed successfully!"
    print_status "Memory caches have been cleared and settings optimized"
}

# Main execution
main() {
    echo "============================================"
    echo "        Ubuntu RAM Cleanup Tool"
    echo "============================================"
    echo ""
    
    check_root
    
    print_warning "This will clear system memory caches and optimize memory usage."
    print_warning "This is safe but may temporarily slow down recently used applications."
    echo ""
    read -p "Do you want to continue? (y/N): " -n 1 -r
    echo ""
    
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        echo ""
        perform_ram_cleanup
    else
        print_status "Operation cancelled by user"
    fi
    
    echo ""
    echo "============================================"
    echo "RAM cleanup process finished!"
    echo "============================================"
}

# Run main function
main "$@"
