#!/bin/bash
#
# limit-logs.sh - System log management and limitation script
# Part of ubuntu-optimize toolkit
#
# This script configures systemd journal and other logging services
# to prevent excessive disk usage by log files
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

# Function to show current log sizes
show_log_sizes() {
    print_status "Current log directory sizes:"
    
    local log_dirs=(
        "/var/log"
        "/var/log/journal"
        "/home/$USER/.cache/upstart"
        "/var/crash"
    )
    
    for log_dir in "${log_dirs[@]}"; do
        if [[ -d "$log_dir" ]]; then
            local size
            size=$(get_dir_size "$log_dir")
            print_status "  $log_dir: $size"
        else
            print_status "  $log_dir: Not found"
        fi
    done
}

# Function to configure systemd journal
configure_systemd_journal() {
    print_status "Configuring systemd journal limits..."
    
    local journal_conf="/etc/systemd/journald.conf"
    local journal_conf_d="/etc/systemd/journald.conf.d"
    local custom_conf="$journal_conf_d/99-ubuntu-optimize.conf"
    
    # Create configuration directory if it doesn't exist
    if sudo mkdir -p "$journal_conf_d" 2>/dev/null; then
        print_status "Created journald configuration directory"
    fi
    
    # Backup original configuration if it exists and hasn't been backed up
    if [[ -f "$journal_conf" ]] && [[ ! -f "$journal_conf.backup" ]]; then
        if sudo cp "$journal_conf" "$journal_conf.backup"; then
            print_success "Created backup of original journald configuration"
        fi
    fi
    
    # Create optimized journal configuration
    print_status "Creating optimized journal configuration..."
    
    local temp_conf
    temp_conf=$(mktemp)
    
    cat > "$temp_conf" << 'EOF'
# Ubuntu Optimize - Journal Configuration
# Optimized for space and performance

[Journal]
# Storage mode: persistent (keep logs across reboots), auto, volatile, or none
Storage=persistent

# Maximum disk space used by journal
SystemMaxUse=100M

# Maximum disk space for individual journal files
SystemMaxFileSize=10M

# Keep journals for this long
MaxRetentionSec=1week

# Maximum number of journal files to keep
SystemMaxFiles=10

# Compress large journal entries
Compress=yes

# Forward to syslog (if needed)
ForwardToSyslog=no

# Forward to wall (emergency messages)
ForwardToWall=yes

# Runtime journal settings (for /run/log/journal)
RuntimeMaxUse=50M
RuntimeMaxFileSize=5M
RuntimeMaxFiles=5

# Rate limiting
RateLimitIntervalSec=30s
RateLimitBurst=1000
EOF
    
    # Install the configuration
    if sudo cp "$temp_conf" "$custom_conf"; then
        print_success "Journal configuration created: $custom_conf"
    else
        print_error "Failed to create journal configuration"
        rm -f "$temp_conf"
        return 1
    fi
    
    rm -f "$temp_conf"
    
    # Restart systemd-journald to apply changes
    print_status "Restarting systemd-journald service..."
    if sudo systemctl restart systemd-journald; then
        print_success "systemd-journald restarted successfully"
    else
        print_warning "Failed to restart systemd-journald"
    fi
}

# Function to configure rsyslog
configure_rsyslog() {
    print_status "Configuring rsyslog rotation..."
    
    local rsyslog_conf="/etc/rsyslog.conf"
    local logrotate_conf="/etc/logrotate.d/rsyslog"
    
    if [[ ! -f "$rsyslog_conf" ]]; then
        print_status "rsyslog not found, skipping rsyslog configuration"
        return 0
    fi
    
    # Configure logrotate for rsyslog
    if [[ -f "$logrotate_conf" ]]; then
        # Backup original logrotate configuration
        if [[ ! -f "$logrotate_conf.backup" ]]; then
            if sudo cp "$logrotate_conf" "$logrotate_conf.backup"; then
                print_success "Created backup of rsyslog logrotate configuration"
            fi
        fi
        
        # Create optimized logrotate configuration
        local temp_logrotate
        temp_logrotate=$(mktemp)
        
        cat > "$temp_logrotate" << 'EOF'
/var/log/syslog
/var/log/mail.info
/var/log/mail.warn
/var/log/mail.err
/var/log/mail.log
/var/log/daemon.log
/var/log/kern.log
/var/log/auth.log
/var/log/user.log
/var/log/lpr.log
/var/log/cron.log
/var/log/debug
/var/log/messages
{
    daily
    missingok
    rotate 7
    compress
    delaycompress
    notifempty
    create 640 syslog adm
    maxsize 10M
    postrotate
        /usr/lib/rsyslog/rsyslog-rotate
    endscript
}
EOF
        
        if sudo cp "$temp_logrotate" "$logrotate_conf"; then
            print_success "Updated rsyslog logrotate configuration"
        else
            print_warning "Failed to update rsyslog logrotate configuration"
        fi
        
        rm -f "$temp_logrotate"
    fi
}

# Function to configure apt history logs
configure_apt_logs() {
    print_status "Configuring APT history log rotation..."
    
    local apt_logrotate="/etc/logrotate.d/apt"
    
    if [[ ! -f "$apt_logrotate" ]]; then
        # Create APT logrotate configuration
        local temp_apt_logrotate
        temp_apt_logrotate=$(mktemp)
        
        cat > "$temp_apt_logrotate" << 'EOF'
/var/log/apt/history.log {
    daily
    missingok
    rotate 4
    compress
    delaycompress
    notifempty
    create 644 root root
    maxsize 5M
}

/var/log/apt/term.log {
    daily
    missingok
    rotate 4
    compress
    delaycompress
    notifempty
    create 644 root root
    maxsize 5M
}
EOF
        
        if sudo cp "$temp_apt_logrotate" "$apt_logrotate"; then
            print_success "Created APT logrotate configuration"
        else
            print_warning "Failed to create APT logrotate configuration"
        fi
        
        rm -f "$temp_apt_logrotate"
    else
        print_status "APT logrotate configuration already exists"
    fi
}

# Function to clean current large logs
clean_large_logs() {
    print_status "Cleaning current large log files..."
    
    local cleaned_count=0
    
    # Find and truncate large log files (larger than 50MB)
    while IFS= read -r -d '' logfile; do
        local size_mb
        size_mb=$(stat -c%s "$logfile" 2>/dev/null | awk '{print int($1/1048576)}' || echo 0)
        
        if [[ $size_mb -gt 50 ]]; then
            print_status "Truncating large log file: $logfile (${size_mb}MB)"
            if sudo truncate -s 10M "$logfile" 2>/dev/null; then
                print_success "Truncated $logfile to 10MB"
                ((cleaned_count++))
            else
                print_warning "Failed to truncate $logfile"
            fi
        fi
    done < <(find /var/log -type f -name "*.log" -print0 2>/dev/null || true)
    
    if [[ $cleaned_count -gt 0 ]]; then
        print_success "Truncated $cleaned_count large log files"
    else
        print_status "No large log files found to clean"
    fi
}

# Function to configure kernel ring buffer
configure_kernel_logs() {
    print_status "Configuring kernel log buffer..."
    
    # Configure dmesg buffer size (if possible)
    local sysctl_conf="/etc/sysctl.d/99-ubuntu-optimize-logs.conf"
    
    local temp_sysctl
    temp_sysctl=$(mktemp)
    
    cat > "$temp_sysctl" << 'EOF'
# Ubuntu Optimize - Kernel log configuration
# Limit kernel log buffer size and rate

# Kernel ring buffer size (reduce if needed)
kernel.printk_ratelimit = 1
kernel.printk_ratelimit_burst = 5

# Reduce kernel log verbosity
kernel.printk = 3 4 1 3
EOF
    
    if sudo cp "$temp_sysctl" "$sysctl_conf"; then
        print_success "Created kernel log configuration"
        
        # Apply the settings
        if sudo sysctl -p "$sysctl_conf" 2>/dev/null; then
            print_success "Applied kernel log settings"
        else
            print_warning "Failed to apply kernel log settings immediately"
        fi
    else
        print_warning "Failed to create kernel log configuration"
    fi
    
    rm -f "$temp_sysctl"
}

# Function to set up automatic cleanup
setup_automatic_cleanup() {
    print_status "Setting up automatic log cleanup..."
    
    local cleanup_script="/usr/local/bin/ubuntu-optimize-logs-cleanup"
    
    # Create cleanup script
    local temp_cleanup
    temp_cleanup=$(mktemp)
    
    cat > "$temp_cleanup" << 'EOF'
#!/bin/bash
# Automatic log cleanup script
# Generated by ubuntu-optimize

# Clean journal logs older than 1 week
journalctl --vacuum-time=1week --quiet

# Clean rotated logs older than 1 week
find /var/log -type f -name "*.gz" -mtime +7 -delete 2>/dev/null || true

# Clean core dumps older than 3 days
find /var/crash -type f -mtime +3 -delete 2>/dev/null || true

# Truncate very large log files
find /var/log -type f -name "*.log" -size +100M -exec truncate -s 50M {} \; 2>/dev/null || true
EOF
    
    if sudo cp "$temp_cleanup" "$cleanup_script"; then
        sudo chmod +x "$cleanup_script"
        print_success "Created automatic cleanup script: $cleanup_script"
    else
        print_warning "Failed to create cleanup script"
    fi
    
    rm -f "$temp_cleanup"
    
    # Add to cron if not already present
    local cron_entry="0 2 * * 0 $cleanup_script >/dev/null 2>&1"
    
    if ! crontab -l 2>/dev/null | grep -q "$cleanup_script"; then
        (crontab -l 2>/dev/null; echo "$cron_entry") | crontab -
        print_success "Added weekly cleanup to crontab"
    else
        print_status "Automatic cleanup already scheduled"
    fi
}

# Function to vacuum systemd journal
vacuum_journal() {
    print_status "Cleaning old journal entries..."
    
    # Vacuum journal by time
    if journalctl --vacuum-time=1week --quiet 2>/dev/null; then
        print_success "Cleaned journal entries older than 1 week"
    else
        print_warning "Failed to vacuum journal by time"
    fi
    
    # Vacuum journal by size
    if journalctl --vacuum-size=100M --quiet 2>/dev/null; then
        print_success "Limited journal size to 100MB"
    else
        print_warning "Failed to vacuum journal by size"
    fi
}

# Main function to perform all log limiting tasks
perform_log_limiting() {
    print_status "Starting log limiting process..."
    
    show_log_sizes
    echo ""
    
    configure_systemd_journal
    echo ""
    configure_rsyslog
    echo ""
    configure_apt_logs
    echo ""
    configure_kernel_logs
    echo ""
    clean_large_logs
    echo ""
    vacuum_journal
    echo ""
    setup_automatic_cleanup
    
    echo ""
    print_status "Final log directory sizes:"
    show_log_sizes
    
    print_success "Log limiting configuration completed successfully!"
    print_status "Logs will now be automatically managed and rotated"
}

# Main execution
main() {
    echo "============================================"
    echo "       Ubuntu Log Limiting Tool"
    echo "============================================"
    echo ""
    
    check_root
    
    print_warning "This will configure log rotation and limit log sizes."
    print_warning "Old logs will be cleaned and future logs will be limited."
    echo ""
    read -p "Do you want to continue? (y/N): " -n 1 -r
    echo ""
    
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        echo ""
        perform_log_limiting
    else
        print_status "Operation cancelled by user"
    fi
    
    echo ""
    echo "============================================"
    echo "Log limiting process finished!"
    echo "============================================"
}

# Run main function
main "$@"
