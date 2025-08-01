#!/bin/bash
#
# disable-tracker.sh - GNOME Tracker disable script
# Part of ubuntu-optimize toolkit
#
# This script safely disables GNOME Tracker services to improve
# system performance by reducing background indexing processes
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

# Function to check if GNOME desktop is being used
check_gnome() {
    if [[ "$XDG_CURRENT_DESKTOP" != *"GNOME"* ]] && [[ "$DESKTOP_SESSION" != *"ubuntu"* ]]; then
        print_warning "GNOME desktop not detected. Tracker services may not be present."
        read -p "Continue anyway? (y/N): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            print_status "Operation cancelled by user"
            exit 0
        fi
    fi
}

# Function to check if tracker is installed
check_tracker() {
    if ! command -v tracker3 &> /dev/null && ! command -v tracker &> /dev/null; then
        print_status "Tracker is not installed on this system"
        return 1
    fi
    return 0
}

# Function to stop tracker services
stop_tracker_services() {
    print_status "Stopping Tracker services..."
    
    local tracker_services=(
        "tracker-extract"
        "tracker-miner-apps"
        "tracker-miner-fs"
        "tracker-store"
        "tracker3-extract"
        "tracker3-miner-apps" 
        "tracker3-miner-fs"
    )
    
    local stopped_count=0
    
    for service in "${tracker_services[@]}"; do
        if pgrep -f "$service" > /dev/null 2>&1; then
            print_status "Stopping $service..."
            if pkill -f "$service" 2>/dev/null; then
                print_success "Stopped $service"
                ((stopped_count++))
            else
                print_warning "Failed to stop $service"
            fi
        else
            print_status "$service is not running"
        fi
    done
    
    if [[ $stopped_count -gt 0 ]]; then
        print_success "Stopped $stopped_count Tracker services"
    else
        print_status "No Tracker services were running"
    fi
}

# Function to disable tracker autostart
disable_tracker_autostart() {
    print_status "Disabling Tracker autostart..."
    
    local autostart_dir="$HOME/.config/autostart"
    mkdir -p "$autostart_dir"
    
    local tracker_desktop_files=(
        "tracker-extract.desktop"
        "tracker-miner-apps.desktop"
        "tracker-miner-fs.desktop"
        "tracker-store.desktop"
        "tracker3-extract.desktop"
        "tracker3-miner-apps.desktop"
        "tracker3-miner-fs.desktop"
    )
    
    local disabled_count=0
    
    for desktop_file in "${tracker_desktop_files[@]}"; do
        local autostart_file="$autostart_dir/$desktop_file"
        
        if [[ ! -f "$autostart_file" ]]; then
            # Create a disabled autostart file
            cat > "$autostart_file" << EOF
[Desktop Entry]
Hidden=true
EOF
            print_success "Created disable file for $desktop_file"
            ((disabled_count++))
        else
            # Check if already disabled
            if grep -q "Hidden=true" "$autostart_file" 2>/dev/null; then
                print_status "$desktop_file is already disabled"
            else
                # Add Hidden=true to existing file
                echo "Hidden=true" >> "$autostart_file"
                print_success "Disabled $desktop_file"
                ((disabled_count++))
            fi
        fi
    done
    
    print_success "Disabled $disabled_count Tracker autostart entries"
}

# Function to disable tracker using gsettings
disable_tracker_gsettings() {
    print_status "Disabling Tracker via GSettings..."
    
    local gsettings_keys=(
        "org.freedesktop.Tracker.Miner.Files crawling-interval -1"
        "org.freedesktop.Tracker.Miner.Files enable-monitors false"
        "org.freedesktop.Tracker.Miner.Files index-recursive-directories []"
        "org.freedesktop.Tracker.Miner.Files index-single-directories []"
        "org.freedesktop.Tracker3.Miner.Files crawling-interval -1"
        "org.freedesktop.Tracker3.Miner.Files enable-monitors false"
        "org.freedesktop.Tracker3.Miner.Files index-recursive-directories []"
        "org.freedesktop.Tracker3.Miner.Files index-single-directories []"
    )
    
    local configured_count=0
    
    for setting in "${gsettings_keys[@]}"; do
        read -r schema key value <<< "$setting"
        
        if gsettings list-schemas | grep -q "$schema" 2>/dev/null; then
            if gsettings set "$schema" "$key" "$value" 2>/dev/null; then
                print_success "Set $schema $key to $value"
                ((configured_count++))
            else
                print_warning "Failed to set $schema $key"
            fi
        else
            print_status "Schema $schema not found (tracker version may vary)"
        fi
    done
    
    print_success "Configured $configured_count GSettings keys"
}

# Function to mask tracker systemd services
mask_tracker_systemd() {
    print_status "Masking Tracker systemd user services..."
    
    local systemd_services=(
        "tracker-extract.service"
        "tracker-miner-apps.service"
        "tracker-miner-fs.service"
        "tracker-store.service" 
        "tracker3-extract.service"
        "tracker3-miner-apps.service"
        "tracker3-miner-fs.service"
    )
    
    local masked_count=0
    
    for service in "${systemd_services[@]}"; do
        if systemctl --user list-unit-files | grep -q "$service" 2>/dev/null; then
            if systemctl --user mask "$service" 2>/dev/null; then
                print_success "Masked $service"
                ((masked_count++))
            else
                print_warning "Failed to mask $service"
            fi
        else
            print_status "$service not found in systemd"
        fi
    done
    
    print_success "Masked $masked_count systemd services"
}

# Function to clear tracker database
clear_tracker_database() {
    print_status "Clearing Tracker database..."
    
    local tracker_dirs=(
        "$HOME/.cache/tracker"
        "$HOME/.cache/tracker3"
        "$HOME/.local/share/tracker"
        "$HOME/.local/share/tracker3"
    )
    
    local cleared_count=0
    
    for tracker_dir in "${tracker_dirs[@]}"; do
        if [[ -d "$tracker_dir" ]]; then
            local dir_size
            dir_size=$(du -sh "$tracker_dir" 2>/dev/null | cut -f1 || echo "0B")
            
            if rm -rf "$tracker_dir" 2>/dev/null; then
                print_success "Cleared $tracker_dir (was $dir_size)"
                ((cleared_count++))
            else
                print_warning "Failed to clear $tracker_dir"
            fi
        else
            print_status "$tracker_dir does not exist"
        fi
    done
    
    if [[ $cleared_count -gt 0 ]]; then
        print_success "Cleared $cleared_count Tracker directories"
    else
        print_status "No Tracker directories found to clear"
    fi
}

# Function to create tracker disable configuration
create_tracker_config() {
    print_status "Creating Tracker disable configuration..."
    
    local config_dir="$HOME/.config/tracker"
    mkdir -p "$config_dir"
    
    # Create tracker.cfg to disable indexing
    cat > "$config_dir/tracker.cfg" << 'EOF'
[General]
verbosity=0
initial-sleep=60
max-bytes=1048576

[Monitors]
enable-monitors=false

[Indexing]
enable-content-indexing=false
enable-thumbnails=false
crawling-interval=-1
EOF
    
    print_success "Created Tracker disable configuration"
}

# Main disable function
perform_tracker_disable() {
    print_status "Starting Tracker disable process..."
    
    stop_tracker_services
    echo ""
    disable_tracker_autostart
    echo ""
    disable_tracker_gsettings
    echo ""
    mask_tracker_systemd
    echo ""
    clear_tracker_database
    echo ""
    create_tracker_config
    
    print_success "Tracker has been disabled successfully!"
    print_warning "Note: You may need to restart your session for all changes to take effect."
}

# Function to show status
show_tracker_status() {
    print_status "Current Tracker status:"
    
    # Check running processes
    local running_processes
    running_processes=$(pgrep -f "tracker" 2>/dev/null | wc -l || echo "0")
    print_status "Running Tracker processes: $running_processes"
    
    # Check systemd services
    local active_services=0
    local systemd_services=(
        "tracker-extract.service"
        "tracker-miner-apps.service"
        "tracker-miner-fs.service"
        "tracker-store.service"
    )
    
    for service in "${systemd_services[@]}"; do
        if systemctl --user is-active "$service" &>/dev/null; then
            ((active_services++))
        fi
    done
    
    print_status "Active systemd services: $active_services"
}

# Main execution
main() {
    echo "============================================"
    echo "       Ubuntu Tracker Disable Tool"
    echo "============================================"
    echo ""
    
    check_root
    check_gnome
    
    if ! check_tracker; then
        print_status "Tracker is not installed, nothing to disable"
        exit 0
    fi
    
    # Show current status
    show_tracker_status
    echo ""
    
    # Ask for confirmation
    print_warning "This will disable GNOME Tracker indexing services."
    print_warning "This may affect file search functionality in GNOME."
    echo ""
    read -p "Do you want to continue? (y/N): " -n 1 -r
    echo ""
    
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        echo ""
        perform_tracker_disable
        echo ""
        show_tracker_status
    else
        print_status "Operation cancelled by user"
    fi
    
    echo ""
    echo "============================================"
    echo "Tracker disable process finished!"
    echo "============================================"
}

# Run main function
main "$@"
