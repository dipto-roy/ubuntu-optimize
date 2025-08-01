#!/bin/bash
#
# full-optimize.sh - Complete Ubuntu optimization script
# Part of ubuntu-optimize toolkit
#
# This script runs all optimization modules in a safe sequence
# for complete system optimization
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
CYAN='\033[0;36m'
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

print_header() {
    echo -e "${CYAN}[STEP]${NC} $1"
}

# Function to check if running as root
check_root() {
    if [[ $EUID -eq 0 ]]; then
        print_error "This script should not be run as root for safety reasons"
        exit 1
    fi
}

# Get the directory where the script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Function to check if all optimization scripts exist
check_scripts() {
    print_status "Checking for optimization scripts..."
    
    local required_scripts=(
        "update-system.sh"
        "clean-apt.sh"
        "clean-cache.sh"
        "clean-snap.sh"
        "clean-temp.sh"
        "limit-logs.sh"
        "ram-clean.sh"
        "trim-ssd.sh"
        "disable-tracker.sh"
        "install-preload.sh"
    )
    
    local missing_scripts=()
    
    for script in "${required_scripts[@]}"; do
        if [[ ! -f "$SCRIPT_DIR/$script" ]]; then
            missing_scripts+=("$script")
        fi
    done
    
    if [[ ${#missing_scripts[@]} -gt 0 ]]; then
        print_error "Missing optimization scripts:"
        for script in "${missing_scripts[@]}"; do
            print_error "  - $script"
        done
        print_error "Please ensure all scripts are in the same directory"
        return 1
    fi
    
    print_success "All optimization scripts found"
    return 0
}

# Function to make scripts executable
make_scripts_executable() {
    print_status "Making optimization scripts executable..."
    
    local scripts=(
        "update-system.sh"
        "clean-apt.sh"
        "clean-cache.sh"
        "clean-snap.sh"
        "clean-temp.sh"
        "limit-logs.sh"
        "ram-clean.sh"
        "trim-ssd.sh"
        "disable-tracker.sh"
        "install-preload.sh"
    )
    
    for script in "${scripts[@]}"; do
        if chmod +x "$SCRIPT_DIR/$script" 2>/dev/null; then
            print_status "Made executable: $script"
        else
            print_warning "Failed to make executable: $script"
        fi
    done
}

# Function to show system information
show_system_info() {
    print_header "System Information"
    echo ""
    
    print_status "Ubuntu Version: $(lsb_release -d | cut -f2)"
    print_status "Kernel Version: $(uname -r)"
    print_status "System Architecture: $(uname -m)"
    print_status "Memory: $(free -h | awk '/^Mem:/{print $2}')"
    print_status "CPU: $(grep "model name" /proc/cpuinfo | head -1 | cut -d: -f2 | xargs)"
    print_status "Disk Usage: $(df -h / | awk 'NR==2 {print $5 " used of " $2}')"
    
    echo ""
}

# Function to get initial system metrics
get_initial_metrics() {
    print_status "Collecting initial system metrics..."
    
    # Store initial values in global variables
    INITIAL_DISK_USAGE=$(df / | awk 'NR==2 {print $3}')
    INITIAL_MEMORY_USED=$(free | awk '/^Mem:/{print $3}')
    INITIAL_CACHE_SIZE=$(du -s ~/.cache 2>/dev/null | cut -f1 || echo "0")
    INITIAL_LOG_SIZE=$(du -s /var/log 2>/dev/null | cut -f1 || echo "0")
    
    print_status "Initial metrics collected"
}

# Function to show optimization progress
show_progress() {
    local step="$1"
    local total="$2"
    local current="$3"
    local description="$4"
    
    local percent=$((current * 100 / total))
    local progress_bar=""
    local completed=$((percent / 5))
    
    for ((i = 0; i < 20; i++)); do
        if [[ $i -lt $completed ]]; then
            progress_bar+="█"
        else
            progress_bar+="░"
        fi
    done
    
    echo -e "\n${CYAN}[$current/$total] $description${NC}"
    echo -e "${BLUE}Progress: [$progress_bar] $percent%${NC}\n"
}

# Function to run optimization script with error handling
run_optimization_script() {
    local script_name="$1"
    local description="$2"
    local optional="${3:-false}"
    
    print_header "Running: $description"
    
    local script_path="$SCRIPT_DIR/$script_name"
    
    if [[ ! -f "$script_path" ]]; then
        if [[ "$optional" == "true" ]]; then
            print_warning "Optional script not found: $script_name"
            return 0
        else
            print_error "Required script not found: $script_name"
            return 1
        fi
    fi
    
    # Run the script and capture output
    if bash "$script_path"; then
        print_success "$description completed successfully"
        return 0
    else
        local exit_code=$?
        if [[ "$optional" == "true" ]]; then
            print_warning "$description failed (optional - continuing)"
            return 0
        else
            print_error "$description failed with exit code $exit_code"
            return $exit_code
        fi
    fi
}

# Function to show final metrics comparison
show_final_metrics() {
    print_header "Optimization Results"
    echo ""
    
    # Calculate disk space saved
    local final_disk_usage
    final_disk_usage=$(df / | awk 'NR==2 {print $3}')
    local disk_saved=$((INITIAL_DISK_USAGE - final_disk_usage))
    local disk_saved_mb=$((disk_saved / 1024))
    
    # Calculate memory changes
    local final_memory_used
    final_memory_used=$(free | awk '/^Mem:/{print $3}')
    local memory_change=$((final_memory_used - INITIAL_MEMORY_USED))
    local memory_change_mb=$((memory_change / 1024))
    
    # Calculate cache reduction
    local final_cache_size
    final_cache_size=$(du -s ~/.cache 2>/dev/null | cut -f1 || echo "0")
    local cache_saved=$((INITIAL_CACHE_SIZE - final_cache_size))
    local cache_saved_mb=$((cache_saved / 1024))
    
    # Calculate log reduction
    local final_log_size
    final_log_size=$(du -s /var/log 2>/dev/null | cut -f1 || echo "0")
    local log_saved=$((INITIAL_LOG_SIZE - final_log_size))
    local log_saved_mb=$((log_saved / 1024))
    
    print_status "Optimization Results:"
    
    if [[ $disk_saved_mb -gt 0 ]]; then
        print_success "Disk space freed: ${disk_saved_mb}MB"
    else
        print_status "Disk space change: ${disk_saved_mb}MB"
    fi
    
    if [[ $cache_saved_mb -gt 0 ]]; then
        print_success "Cache reduced: ${cache_saved_mb}MB"
    fi
    
    if [[ $log_saved_mb -gt 0 ]]; then
        print_success "Log files reduced: ${log_saved_mb}MB"
    fi
    
    if [[ $memory_change_mb -lt 0 ]]; then
        print_success "Memory freed: $((memory_change_mb * -1))MB"
    elif [[ $memory_change_mb -gt 0 ]]; then
        print_status "Memory usage increased: ${memory_change_mb}MB"
    else
        print_status "Memory usage unchanged"
    fi
    
    echo ""
    print_status "Current system status:"
    print_status "Available memory: $(free -h | awk '/^Mem:/{print $7}')"
    print_status "Free disk space: $(df -h / | awk 'NR==2 {print $4}')"
    
    echo ""
}

# Function to create optimization log
create_optimization_log() {
    local log_dir="$HOME/.ubuntu-optimize-logs"
    mkdir -p "$log_dir"
    
    local log_file="$log_dir/full-optimize-$(date +%Y%m%d-%H%M%S).log"
    
    cat > "$log_file" << EOF
# Ubuntu Full Optimization Log
# Date: $(date)
# User: $USER
# System: $(lsb_release -d | cut -f2)

# Optimization completed successfully
# Initial disk usage: ${INITIAL_DISK_USAGE}KB
# Final disk usage: $(df / | awk 'NR==2 {print $3}')KB
# Space saved: $((INITIAL_DISK_USAGE - $(df / | awk 'NR==2 {print $3}')))KB

# System information after optimization:
$(uname -a)
$(free -h)
$(df -h)
$(systemctl list-timers fstrim.timer 2>/dev/null || echo "TRIM timer not active")
EOF
    
    print_success "Optimization log saved: $log_file"
}

# Main optimization function
perform_full_optimization() {
    local total_steps=10
    local current_step=0
    
    print_header "Starting Full Ubuntu Optimization"
    echo ""
    
    get_initial_metrics
    
    # Step 1: Update system
    ((current_step++))
    show_progress "System Update" $total_steps $current_step "Updating system packages and security patches"
    if ! run_optimization_script "update-system.sh" "System Update"; then
        print_warning "System update failed, but continuing with other optimizations"
    fi
    
    # Step 2: Clean APT
    ((current_step++))
    show_progress "APT Cleanup" $total_steps $current_step "Cleaning APT package cache and orphaned packages"
    run_optimization_script "clean-apt.sh" "APT Package Cleanup"
    
    # Step 3: Clean Snap
    ((current_step++))
    show_progress "Snap Cleanup" $total_steps $current_step "Cleaning Snap packages and old revisions"
    run_optimization_script "clean-snap.sh" "Snap Package Cleanup" true
    
    # Step 4: Clean cache
    ((current_step++))
    show_progress "Cache Cleanup" $total_steps $current_step "Cleaning user and application caches"
    run_optimization_script "clean-cache.sh" "Cache Cleanup"
    
    # Step 5: Clean temporary files
    ((current_step++))
    show_progress "Temp Cleanup" $total_steps $current_step "Cleaning temporary files and directories"
    run_optimization_script "clean-temp.sh" "Temporary Files Cleanup"
    
    # Step 6: Limit logs
    ((current_step++))
    show_progress "Log Management" $total_steps $current_step "Configuring log rotation and cleanup"
    run_optimization_script "limit-logs.sh" "Log Management" true
    
    # Step 7: Optimize SSD (if applicable)
    ((current_step++))
    show_progress "SSD Optimization" $total_steps $current_step "Optimizing SSD performance and TRIM"
    run_optimization_script "trim-ssd.sh" "SSD Optimization" true
    
    # Step 8: RAM cleanup
    ((current_step++))
    show_progress "Memory Cleanup" $total_steps $current_step "Cleaning and optimizing memory usage"
    run_optimization_script "ram-clean.sh" "Memory Cleanup" true
    
    # Step 9: Disable tracker (optional)
    ((current_step++))
    show_progress "Tracker Disable" $total_steps $current_step "Disabling GNOME Tracker (optional)"
    print_warning "Tracker disable is optional and affects file search functionality"
    read -p "Do you want to disable GNOME Tracker? (y/N): " -n 1 -r
    echo ""
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        run_optimization_script "disable-tracker.sh" "GNOME Tracker Disable" true
    else
        print_status "Skipping Tracker disable"
    fi
    
    # Step 10: Install preload (optional)
    ((current_step++))
    show_progress "Preload Installation" $total_steps $current_step "Installing and configuring preload (optional)"
    print_warning "Preload installation is optional and requires 2GB+ RAM"
    read -p "Do you want to install preload? (y/N): " -n 1 -r
    echo ""
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        run_optimization_script "install-preload.sh" "Preload Installation" true
    else
        print_status "Skipping preload installation"
    fi
    
    echo ""
    print_header "Optimization Complete!"
    echo ""
    
    show_final_metrics
    create_optimization_log
    
    print_success "Full Ubuntu optimization completed successfully!"
    print_status "Your system has been optimized for better performance"
    
    # Check if reboot is recommended
    if [[ -f /var/run/reboot-required ]]; then
        echo ""
        print_warning "A system reboot is recommended to complete the optimization"
        read -p "Do you want to reboot now? (y/N): " -n 1 -r
        echo ""
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            print_status "Rebooting in 10 seconds..."
            sleep 10
            sudo reboot
        fi
    fi
}

# Main execution
main() {
    clear
    echo "================================================"
    echo "          Ubuntu Full Optimization Tool"
    echo "================================================"
    echo ""
    echo "This tool will perform a comprehensive optimization"
    echo "of your Ubuntu system including:"
    echo ""
    echo "✓ System updates and security patches"
    echo "✓ Package cache cleanup (APT, Snap)"
    echo "✓ User cache and temporary files cleanup"
    echo "✓ Log file management and rotation"
    echo "✓ Memory optimization and cleanup"
    echo "✓ SSD optimization (TRIM configuration)"
    echo "✓ Optional: GNOME Tracker disable"
    echo "✓ Optional: Preload installation"
    echo ""
    echo "================================================"
    echo ""
    
    check_root
    
    if ! check_scripts; then
        exit 1
    fi
    
    make_scripts_executable
    show_system_info
    
    print_warning "This process may take 15-30 minutes depending on your system"
    print_warning "Please ensure you have a stable internet connection"
    print_warning "Close important applications before proceeding"
    echo ""
    read -p "Do you want to start the full optimization? (y/N): " -n 1 -r
    echo ""
    
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        echo ""
        perform_full_optimization
    else
        print_status "Full optimization cancelled by user"
        print_status "You can run individual optimization scripts manually"
    fi
    
    echo ""
    echo "================================================"
    echo "Full optimization process finished!"
    echo "================================================"
}

# Run main function
main "$@"
