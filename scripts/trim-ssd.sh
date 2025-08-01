#!/bin/bash
#
# trim-ssd.sh - SSD TRIM optimization script
# Part of ubuntu-optimize toolkit
#
# This script optimizes SSD performance by running TRIM commands
# and configuring automatic TRIM scheduling
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

# Function to detect SSD drives
detect_ssds() {
    print_status "Detecting SSD drives..."
    
    local ssd_drives=()
    
    # Method 1: Check /sys/block for rotation rate
    for device in /sys/block/sd*; do
        if [[ -f "$device/queue/rotational" ]]; then
            local rotational
            rotational=$(cat "$device/queue/rotational" 2>/dev/null || echo "1")
            if [[ "$rotational" == "0" ]]; then
                local device_name
                device_name=$(basename "$device")
                ssd_drives+=("/dev/$device_name")
            fi
        fi
    done
    
    # Method 2: Check for NVMe drives
    for device in /dev/nvme*n1; do
        if [[ -b "$device" ]]; then
            ssd_drives+=("$device")
        fi
    done
    
    # Method 3: Check using lsblk
    while IFS= read -r line; do
        local device
        device=$(echo "$line" | awk '{print "/dev/" $1}')
        if [[ -b "$device" ]] && [[ ! " ${ssd_drives[*]} " =~ " $device " ]]; then
            ssd_drives+=("$device")
        fi
    done < <(lsblk -d -o NAME,ROTA | awk '$2=="0" {print $1}' 2>/dev/null || true)
    
    if [[ ${#ssd_drives[@]} -eq 0 ]]; then
        print_warning "No SSD drives detected on this system"
        return 1
    else
        print_success "Detected ${#ssd_drives[@]} SSD drive(s):"
        for drive in "${ssd_drives[@]}"; do
            local drive_info
            drive_info=$(lsblk -d -o NAME,SIZE,MODEL "$drive" 2>/dev/null | tail -1 || echo "Unknown")
            print_status "  $drive: $drive_info"
        done
        
        # Store in global variable for other functions
        DETECTED_SSDS=("${ssd_drives[@]}")
    fi
    
    return 0
}

# Function to check TRIM support
check_trim_support() {
    print_status "Checking TRIM support..."
    
    local trim_supported=true
    
    for drive in "${DETECTED_SSDS[@]}"; do
        print_status "Checking TRIM support for $drive..."
        
        # Check if the drive supports TRIM
        if lsblk -D -o NAME,DISC-GRAN,DISC-MAX "$drive" 2>/dev/null | grep -q "0B.*0B"; then
            print_warning "  $drive: TRIM may not be supported"
            trim_supported=false
        else
            print_success "  $drive: TRIM supported"
        fi
        
        # Additional check using hdparm (if available)
        if command -v hdparm &> /dev/null; then
            local trim_info
            trim_info=$(sudo hdparm -I "$drive" 2>/dev/null | grep -i "trim\|discard" || echo "")
            if [[ -n "$trim_info" ]]; then
                print_status "  $drive TRIM info: $(echo "$trim_info" | tr '\n' ' ')"
            fi
        fi
    done
    
    if [[ "$trim_supported" == false ]]; then
        print_warning "Some drives may not support TRIM properly"
        return 1
    fi
    
    return 0
}

# Function to check current TRIM status
check_trim_status() {
    print_status "Checking current TRIM configuration..."
    
    # Check if fstrim timer is enabled
    if systemctl is-enabled fstrim.timer &>/dev/null; then
        print_success "fstrim.timer is enabled"
    else
        print_status "fstrim.timer is not enabled"
    fi
    
    # Check if fstrim timer is active
    if systemctl is-active fstrim.timer &>/dev/null; then
        print_success "fstrim.timer is active"
    else
        print_status "fstrim.timer is not active"
    fi
    
    # Check last fstrim run
    local last_run
    last_run=$(systemctl status fstrim.service 2>/dev/null | grep -E "Active:|since" | head -1 || echo "Never run")
    print_status "Last fstrim run: $last_run"
    
    # Check mount options for TRIM
    print_status "Checking filesystem mount options for TRIM..."
    local filesystems
    filesystems=$(mount | grep -E "ext[234]|xfs|btrfs" | grep -E "$(echo "${DETECTED_SSDS[@]}" | tr ' ' '|')" 2>/dev/null || true)
    
    if [[ -n "$filesystems" ]]; then
        while IFS= read -r filesystem; do
            local mount_point
            local options
            mount_point=$(echo "$filesystem" | awk '{print $3}')
            options=$(echo "$filesystem" | grep -o "(.*)" | tr -d "()")
            
            if echo "$options" | grep -q "discard"; then
                print_success "  $mount_point: TRIM enabled (discard option)"
            else
                print_status "  $mount_point: TRIM not enabled in mount options"
            fi
        done <<< "$filesystems"
    fi
}

# Function to run manual TRIM
run_manual_trim() {
    print_status "Running manual TRIM on all mounted filesystems..."
    
    # Run fstrim on all mounted filesystems
    if sudo fstrim -v -a 2>/dev/null; then
        print_success "Manual TRIM completed successfully"
    else
        print_warning "Manual TRIM failed or no filesystems support TRIM"
        
        # Try individual filesystems
        local mounted_fs
        mounted_fs=$(findmnt -D -o TARGET,FSTYPE | grep -E "ext[234]|xfs|btrfs" | awk '{print $1}' || true)
        
        if [[ -n "$mounted_fs" ]]; then
            while IFS= read -r mount_point; do
                print_status "Attempting TRIM on $mount_point..."
                if sudo fstrim -v "$mount_point" 2>/dev/null; then
                    print_success "  TRIM completed on $mount_point"
                else
                    print_warning "  TRIM failed on $mount_point"
                fi
            done <<< "$mounted_fs"
        fi
    fi
}

# Function to enable automatic TRIM
enable_automatic_trim() {
    print_status "Enabling automatic TRIM scheduling..."
    
    # Enable fstrim.timer
    if sudo systemctl enable fstrim.timer 2>/dev/null; then
        print_success "fstrim.timer enabled"
    else
        print_warning "Failed to enable fstrim.timer"
        return 1
    fi
    
    # Start fstrim.timer
    if sudo systemctl start fstrim.timer 2>/dev/null; then
        print_success "fstrim.timer started"
    else
        print_warning "Failed to start fstrim.timer"
        return 1
    fi
    
    # Check the timer schedule
    local timer_info
    timer_info=$(systemctl list-timers fstrim.timer 2>/dev/null | grep fstrim || echo "Schedule unknown")
    print_status "TRIM schedule: $timer_info"
    
    return 0
}

# Function to configure TRIM mount options
configure_trim_mounts() {
    print_status "Configuring TRIM mount options..."
    
    local fstab_file="/etc/fstab"
    local fstab_backup="/etc/fstab.backup-ubuntu-optimize"
    
    # Create backup of fstab
    if [[ ! -f "$fstab_backup" ]]; then
        if sudo cp "$fstab_file" "$fstab_backup"; then
            print_success "Created backup of /etc/fstab"
        else
            print_warning "Failed to create fstab backup"
            return 1
        fi
    fi
    
    print_warning "Adding 'discard' option to fstab can impact performance on some SSDs"
    print_warning "Weekly TRIM via systemd timer is often preferred"
    echo ""
    read -p "Do you want to add 'discard' option to fstab? (y/N): " -n 1 -r
    echo ""
    
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        # Add discard option to SSD filesystems in fstab
        local temp_fstab
        temp_fstab=$(mktemp)
        
        local modified=false
        
        while IFS= read -r line; do
            # Skip comments and empty lines
            if [[ "$line" =~ ^[[:space:]]*# ]] || [[ -z "${line// }" ]]; then
                echo "$line" >> "$temp_fstab"
                continue
            fi
            
            # Parse fstab entry
            local device filesystem type options dump pass
            read -r device filesystem type options dump pass <<< "$line"
            
            # Check if this is an SSD filesystem that supports TRIM
            local is_ssd_fs=false
            if [[ "$type" =~ ^(ext[234]|xfs|btrfs)$ ]]; then
                for ssd in "${DETECTED_SSDS[@]}"; do
                    if [[ "$device" =~ $ssd ]] || [[ "$device" =~ UUID.*$ ]]; then
                        is_ssd_fs=true
                        break
                    fi
                done
            fi
            
            if [[ "$is_ssd_fs" == true ]] && [[ ! "$options" =~ discard ]]; then
                # Add discard option
                if [[ "$options" == "defaults" ]]; then
                    options="defaults,discard"
                else
                    options="$options,discard"
                fi
                modified=true
                print_status "Added discard option to: $device ($filesystem)"
            fi
            
            echo "$device $filesystem $type $options $dump $pass" >> "$temp_fstab"
        done < "$fstab_file"
        
        if [[ "$modified" == true ]]; then
            if sudo cp "$temp_fstab" "$fstab_file"; then
                print_success "Updated /etc/fstab with TRIM options"
                print_warning "Changes will take effect after reboot"
            else
                print_error "Failed to update /etc/fstab"
            fi
        else
            print_status "No changes needed in /etc/fstab"
        fi
        
        rm -f "$temp_fstab"
    else
        print_status "Skipped adding discard option to fstab"
    fi
}

# Function to optimize SSD settings
optimize_ssd_settings() {
    print_status "Optimizing SSD settings..."
    
    local sysctl_conf="/etc/sysctl.d/99-ubuntu-optimize-ssd.conf"
    
    # Create SSD optimization configuration
    local temp_conf
    temp_conf=$(mktemp)
    
    cat > "$temp_conf" << 'EOF'
# Ubuntu Optimize - SSD optimization settings

# Reduce swappiness for SSD longevity
vm.swappiness=1

# Optimize dirty page writebacks for SSD
vm.dirty_background_ratio=5
vm.dirty_ratio=10
vm.dirty_expire_centisecs=3000
vm.dirty_writeback_centisecs=500

# Reduce disk I/O scheduler overhead
# Note: These settings are applied via udev rules
EOF
    
    if sudo cp "$temp_conf" "$sysctl_conf"; then
        print_success "SSD optimization settings created"
        
        # Apply the settings
        if sudo sysctl -p "$sysctl_conf" 2>/dev/null; then
            print_success "SSD optimization settings applied"
        else
            print_warning "Failed to apply SSD settings immediately"
        fi
    else
        print_warning "Failed to create SSD optimization settings"
    fi
    
    rm -f "$temp_conf"
    
    # Configure I/O scheduler for SSDs
    local udev_rule="/etc/udev/rules.d/60-ssd-scheduler.rules"
    
    local temp_udev
    temp_udev=$(mktemp)
    
    cat > "$temp_udev" << 'EOF'
# Ubuntu Optimize - SSD I/O scheduler optimization
# Set appropriate I/O scheduler for SSDs

# For SATA SSDs, use mq-deadline or noop
ACTION=="add|change", KERNEL=="sd[a-z]", ATTR{queue/rotational}=="0", ATTR{queue/scheduler}="mq-deadline"

# For NVMe SSDs, use none (no scheduler needed)
ACTION=="add|change", KERNEL=="nvme[0-9]n[0-9]", ATTR{queue/scheduler}="none"
EOF
    
    if sudo cp "$temp_udev" "$udev_rule"; then
        print_success "SSD I/O scheduler rules created"
        
        # Reload udev rules
        if sudo udevadm control --reload-rules 2>/dev/null; then
            print_success "Udev rules reloaded"
        fi
    else
        print_warning "Failed to create SSD I/O scheduler rules"
    fi
    
    rm -f "$temp_udev"
}

# Function to show SSD health information
show_ssd_health() {
    print_status "SSD health information:"
    
    for drive in "${DETECTED_SSDS[@]}"; do
        print_status "Drive: $drive"
        
        # Show basic info
        if command -v lsblk &> /dev/null; then
            local drive_info
            drive_info=$(lsblk -d -o NAME,SIZE,MODEL,SERIAL "$drive" 2>/dev/null | tail -1 || echo "Info unavailable")
            print_status "  Info: $drive_info"
        fi
        
        # Show SMART info if available
        if command -v smartctl &> /dev/null; then
            local health_status
            health_status=$(sudo smartctl -H "$drive" 2>/dev/null | grep "SMART overall-health" | awk -F: '{print $2}' | xargs || echo "Unknown")
            print_status "  Health: $health_status"
            
            # Show wear leveling for SSDs
            local wear_level
            wear_level=$(sudo smartctl -A "$drive" 2>/dev/null | grep -E "Wear_Leveling_Count|Media_Wearout_Indicator" | awk '{print $4}' | head -1 || echo "N/A")
            if [[ "$wear_level" != "N/A" ]]; then
                print_status "  Wear Level: $wear_level%"
            fi
        else
            print_status "  Install smartmontools for detailed health info: sudo apt install smartmontools"
        fi
        
        echo ""
    done
}

# Main SSD optimization function
perform_ssd_optimization() {
    print_status "Starting SSD TRIM optimization process..."
    
    # Detect SSDs
    if ! detect_ssds; then
        print_error "No SSDs detected, aborting SSD optimization"
        return 1
    fi
    
    echo ""
    check_trim_support
    echo ""
    check_trim_status
    echo ""
    show_ssd_health
    echo ""
    
    # Ask for confirmation
    print_warning "This will optimize SSD settings and enable automatic TRIM"
    echo ""
    read -p "Do you want to continue? (y/N): " -n 1 -r
    echo ""
    
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        echo ""
        run_manual_trim
        echo ""
        enable_automatic_trim
        echo ""
        configure_trim_mounts
        echo ""
        optimize_ssd_settings
        
        print_success "SSD optimization completed successfully!"
        print_status "Automatic TRIM is now enabled and will run weekly"
    else
        print_status "SSD optimization cancelled by user"
    fi
}

# Main execution
main() {
    echo "============================================"
    echo "        Ubuntu SSD TRIM Optimizer"
    echo "============================================"
    echo ""
    
    check_root
    perform_ssd_optimization
    
    echo ""
    echo "============================================"
    echo "SSD optimization process finished!"
    echo "============================================"
}

# Run main function
main "$@"
