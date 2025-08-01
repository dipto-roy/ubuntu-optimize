#!/bin/bash
#
# ubuntu-optimize.sh - Main CLI entry point for Ubuntu optimization toolkit
# 
# A comprehensive Ubuntu optimization toolkit with modular scripts
# for system cleanup, performance optimization, and maintenance
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
BOLD='\033[1m'
NC='\033[0m' # No Color

# Script version and info
VERSION="1.0.0"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SCRIPTS_DIR="$SCRIPT_DIR/scripts"

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
    echo -e "${CYAN}${BOLD}$1${NC}"
}

# Function to show help
show_help() {
    cat << EOF
${BOLD}Ubuntu Optimize Toolkit v$VERSION${NC}

A comprehensive Ubuntu optimization toolkit for system cleanup,
performance optimization, and maintenance.

${BOLD}USAGE:${NC}
    ubuntu-optimize [COMMAND] [OPTIONS]

${BOLD}COMMANDS:${NC}
    ${CYAN}full${NC}              Run complete optimization (all modules)
    ${CYAN}update${NC}            Update system packages and security patches
    ${CYAN}clean-apt${NC}         Clean APT package cache and orphaned packages
    ${CYAN}clean-cache${NC}       Clean user cache and temporary files  
    ${CYAN}clean-snap${NC}        Clean Snap packages and old revisions
    ${CYAN}clean-temp${NC}        Clean system temporary files and logs
    ${CYAN}ram-clean${NC}         Clean and optimize memory usage
    ${CYAN}limit-logs${NC}        Configure log rotation and cleanup
    ${CYAN}trim-ssd${NC}          Optimize SSD performance and enable TRIM
    ${CYAN}disable-tracker${NC}   Disable GNOME Tracker indexing services
    ${CYAN}install-preload${NC}   Install and configure preload daemon
    
    ${CYAN}status${NC}            Show system status and optimization info
    ${CYAN}list${NC}              List all available optimization modules
    ${CYAN}version${NC}           Show version information
    ${CYAN}help${NC}              Show this help message

${BOLD}OPTIONS:${NC}
    -v, --verbose     Enable verbose output
    -q, --quiet       Suppress non-error output
    -y, --yes         Automatically answer yes to prompts
    -h, --help        Show this help message

${BOLD}EXAMPLES:${NC}
    ubuntu-optimize full              # Run complete optimization
    ubuntu-optimize clean-cache       # Clean only cache files
    ubuntu-optimize update --yes      # Update system without prompts
    ubuntu-optimize status            # Show system status

${BOLD}SAFETY:${NC}
    - All operations are designed to be safe for daily use
    - Scripts check for root access and refuse to run as root
    - Backup information is created before major changes
    - Individual modules can be run independently

${BOLD}REQUIREMENTS:${NC}
    - Ubuntu LTS 18.04 or newer
    - Internet connection (for updates)
    - Sufficient disk space for operations

For more information, visit: https://github.com/dipto-roy/ubuntu-optimize
EOF
}

# Function to show version
show_version() {
    cat << EOF
${BOLD}Ubuntu Optimize Toolkit${NC}
Version: $VERSION
Compatible: Ubuntu LTS 18.04+
Author: Ubuntu Optimize Team

System Information:
$(lsb_release -d 2>/dev/null || echo "Distribution: Unknown")
Kernel: $(uname -r)
Architecture: $(uname -m)
EOF
}

# Function to list available modules
list_modules() {
    print_header "Available Optimization Modules:"
    echo ""
    
    local modules=(
        "update:Update system packages and security patches"
        "clean-apt:Clean APT package cache and orphaned packages"
        "clean-cache:Clean user cache and temporary files"
        "clean-snap:Clean Snap packages and old revisions"
        "clean-temp:Clean system temporary files and logs"
        "ram-clean:Clean and optimize memory usage"
        "limit-logs:Configure log rotation and cleanup"
        "trim-ssd:Optimize SSD performance and enable TRIM"
        "disable-tracker:Disable GNOME Tracker indexing services"
        "install-preload:Install and configure preload daemon"
        "full:Run complete optimization (all modules)"
    )
    
    for module in "${modules[@]}"; do
        local name=$(echo "$module" | cut -d: -f1)
        local desc=$(echo "$module" | cut -d: -f2)
        printf "  ${CYAN}%-18s${NC} %s\n" "$name" "$desc"
    done
    
    echo ""
    print_status "Run 'ubuntu-optimize [module-name]' to execute a specific module"
    print_status "Run 'ubuntu-optimize full' to execute all optimization modules"
}

# Function to show system status
show_status() {
    print_header "Ubuntu System Status"
    echo ""
    
    # System information
    print_status "System Information:"
    echo "  OS: $(lsb_release -d | cut -f2)"
    echo "  Kernel: $(uname -r)"
    echo "  Architecture: $(uname -m)"
    echo "  Uptime: $(uptime -p 2>/dev/null || uptime | cut -d' ' -f3-)"
    echo ""
    
    # Memory information
    print_status "Memory Usage:"
    free -h | while read -r line; do
        echo "  $line"
    done
    echo ""
    
    # Disk usage
    print_status "Disk Usage:"
    df -h | grep -E "^/dev|^tmpfs" | head -5 | while read -r line; do
        echo "  $line"
    done
    echo ""
    
    # Package information
    print_status "Package Information:"
    local total_packages
    total_packages=$(dpkg --get-selections | grep -c "install" || echo "0")
    echo "  Installed packages: $total_packages"
    
    local updates_available
    updates_available=$(apt list --upgradable 2>/dev/null | wc -l)
    updates_available=$((updates_available - 1))
    echo "  Available updates: $updates_available"
    
    # Snap packages
    if command -v snap &> /dev/null; then
        local snap_packages
        snap_packages=$(snap list 2>/dev/null | tail -n +2 | wc -l || echo "0")
        echo "  Snap packages: $snap_packages"
    fi
    echo ""
    
    # Services status
    print_status "Optimization Services:"
    
    # Check fstrim timer
    if systemctl is-enabled fstrim.timer &>/dev/null; then
        echo "  TRIM timer: Enabled"
    else
        echo "  TRIM timer: Disabled"
    fi
    
    # Check preload
    if systemctl --user is-active preload.service &>/dev/null 2>&1; then
        echo "  Preload: Running"
    elif command -v preload &> /dev/null; then
        echo "  Preload: Installed but not running"
    else
        echo "  Preload: Not installed"
    fi
    
    # Check tracker
    if pgrep -f "tracker" > /dev/null 2>&1; then
        echo "  GNOME Tracker: Running"
    else
        echo "  GNOME Tracker: Not running"
    fi
    
    echo ""
    
    # Last optimization log
    local log_dir="$HOME/.ubuntu-optimize-logs"
    if [[ -d "$log_dir" ]]; then
        local last_log
        last_log=$(ls -t "$log_dir"/*.log 2>/dev/null | head -1 || echo "")
        if [[ -n "$last_log" ]]; then
            local log_date
            log_date=$(stat -c %y "$last_log" | cut -d' ' -f1)
            print_status "Last optimization: $log_date"
        else
            print_status "Last optimization: Never"
        fi
    else
        print_status "Last optimization: Never"
    fi
}

# Function to check if running as root
check_root() {
    if [[ $EUID -eq 0 ]]; then
        print_error "This script should not be run as root for safety reasons"
        print_error "Please run as a regular user with sudo privileges"
        exit 1
    fi
}

# Function to check if script exists
check_script_exists() {
    local script_name="$1"
    local script_path="$SCRIPTS_DIR/$script_name"
    
    if [[ ! -f "$script_path" ]]; then
        print_error "Script not found: $script_path"
        print_error "Please ensure all optimization scripts are in the scripts/ directory"
        return 1
    fi
    
    return 0
}

# Function to make script executable
make_executable() {
    local script_path="$1"
    
    if [[ ! -x "$script_path" ]]; then
        if chmod +x "$script_path" 2>/dev/null; then
            print_status "Made script executable: $(basename "$script_path")"
        else
            print_warning "Could not make script executable: $(basename "$script_path")"
        fi
    fi
}

# Function to run optimization script
run_script() {
    local script_name="$1"
    local script_path="$SCRIPTS_DIR/$script_name"
    
    if ! check_script_exists "$script_name"; then
        return 1
    fi
    
    make_executable "$script_path"
    
    print_status "Running optimization: $(basename "$script_name" .sh)"
    echo ""
    
    # Run the script
    if bash "$script_path"; then
        echo ""
        print_success "Optimization completed: $(basename "$script_name" .sh)"
        return 0
    else
        local exit_code=$?
        echo ""
        print_error "Optimization failed: $(basename "$script_name" .sh) (exit code: $exit_code)"
        return $exit_code
    fi
}

# Function to validate command
validate_command() {
    local command="$1"
    
    local valid_commands=(
        "full" "update" "clean-apt" "clean-cache" "clean-snap" 
        "clean-temp" "ram-clean" "limit-logs" "trim-ssd" 
        "disable-tracker" "install-preload" "status" "list" 
        "version" "help"
    )
    
    for valid_cmd in "${valid_commands[@]}"; do
        if [[ "$command" == "$valid_cmd" ]]; then
            return 0
        fi
    done
    
    return 1
}

# Main function
main() {
    # Parse command line arguments
    local command=""
    local verbose=false
    local quiet=false
    local auto_yes=false
    
    while [[ $# -gt 0 ]]; do
        case $1 in
            -v|--verbose)
                verbose=true
                shift
                ;;
            -q|--quiet)
                quiet=true
                shift
                ;;
            -y|--yes)
                auto_yes=true
                export UBUNTU_OPTIMIZE_AUTO_YES="true"
                shift
                ;;
            -h|--help|help)
                show_help
                exit 0
                ;;
            version)
                show_version
                exit 0
                ;;
            status)
                check_root
                show_status
                exit 0
                ;;
            list)
                list_modules
                exit 0
                ;;
            full|update|clean-apt|clean-cache|clean-snap|clean-temp|ram-clean|limit-logs|trim-ssd|disable-tracker|install-preload)
                command="$1"
                shift
                ;;
            *)
                print_error "Unknown option: $1"
                echo ""
                show_help
                exit 1
                ;;
        esac
    done
    
    # If no command provided, show help
    if [[ -z "$command" ]]; then
        show_help
        exit 0
    fi
    
    # Validate command
    if ! validate_command "$command"; then
        print_error "Invalid command: $command"
        echo ""
        list_modules
        exit 1
    fi
    
    # Check if running as root
    check_root
    
    # Show header
    if [[ "$quiet" != true ]]; then
        clear
        print_header "Ubuntu Optimize Toolkit v$VERSION"
        echo ""
    fi
    
    # Set environment variables for scripts
    export UBUNTU_OPTIMIZE_VERBOSE="$verbose"
    export UBUNTU_OPTIMIZE_QUIET="$quiet"
    
    # Execute command
    case "$command" in
        "full")
            run_script "full-optimize.sh"
            ;;
        "update")
            run_script "update-system.sh"
            ;;
        "clean-apt")
            run_script "clean-apt.sh"
            ;;
        "clean-cache")
            run_script "clean-cache.sh"
            ;;
        "clean-snap")
            run_script "clean-snap.sh"
            ;;
        "clean-temp")
            run_script "clean-temp.sh"
            ;;
        "ram-clean")
            run_script "ram-clean.sh"
            ;;
        "limit-logs")
            run_script "limit-logs.sh"
            ;;
        "trim-ssd")
            run_script "trim-ssd.sh"
            ;;
        "disable-tracker")
            run_script "disable-tracker.sh"
            ;;
        "install-preload")
            run_script "install-preload.sh"
            ;;
    esac
    
    local exit_code=$?
    
    if [[ "$quiet" != true ]]; then
        echo ""
        if [[ $exit_code -eq 0 ]]; then
            print_success "Operation completed successfully!"
        else
            print_error "Operation failed with exit code: $exit_code"
        fi
    fi
    
    exit $exit_code
}

# Run main function with all arguments
main "$@"
