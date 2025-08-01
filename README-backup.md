# Ubuntu Optimize Toolkit

A comprehensive, modular CLI toolkit for Ubuntu system optimization, cleanup, and performance enhancement. Designed for Ubuntu LTS systems with safety and efficiency in mind.

> **Dedicated Repository**: This is the official repository for the Ubuntu Optimize Toolkit. Get the latest version and updates from [dipto-roy/ubuntu-optimize](https://github.com/dipto-roy/ubuntu-optimize).

## 🚀 Features

### Core Optimization Modules
- **System Updates** - Complete system package updates and security patches
- **APT Cleanup** - Clean package cache, remove orphaned packages, update database
- **Cache Cleanup** - Clean user cache, thumbnails, trash, and temporary files
- **Snap Cleanup** - Remove old snap revisions and clean snap cache
- **Temporary Files** - Clean system temp directories and browser cache
- **Memory Optimization** - Clear memory caches and optimize RAM usage
- **Log Management** - Configure log rotation and limit log file sizes
- **SSD Optimization** - Enable TRIM, optimize I/O scheduler for SSDs
- **Tracker Disable** - Disable GNOME Tracker indexing for better performance
- **Preload Installation** - Install and configure preload for faster app startup

### Key Benefits
✅ **Safe & Non-destructive** - All operations designed for regular use  
✅ **Modular Design** - Run individual modules or complete optimization  
✅ **Intelligent Checks** - Automatic system detection and compatibility  
✅ **Detailed Feedback** - Comprehensive status reporting and error handling  
✅ **Backup Creation** - Automatic backups before major changes  
✅ **Root Safety** - Refuses to run as root for security  

## 📋 Requirements

- **OS**: Ubuntu LTS 18.04 or newer
- **Memory**: 1GB RAM minimum (2GB+ recommended for preload)
- **Disk**: 100MB free space for operations
- **Network**: Internet connection for system updates
- **Permissions**: User account with sudo privileges

## 🛠️ Installation

### Quick Installation (Recommended)
```bash
# Clone the repository
git clone https://github.com/dipto-roy/ubuntu-optimize.git
cd ubuntu-optimize

# Make all scripts executable
chmod +x ubuntu-optimize.sh
chmod +x scripts/*.sh

# Test the installation
./ubuntu-optimize.sh --help
```

### System-wide Installation
```bash
# After running the quick installation above
# Install the main script system-wide
sudo cp ubuntu-optimize.sh /usr/local/bin/ubuntu-optimize

# Install bash auto-completion
sudo cp ubuntu-optimize-autocomplete.sh /etc/bash_completion.d/ubuntu-optimize

# Reload bash completion (or restart terminal)
source /etc/bash_completion.d/ubuntu-optimize

# Now you can run from anywhere
ubuntu-optimize --help
```

### Manual Installation
```bash
# Download and extract (if git is not available)
wget https://github.com/dipto-roy/ubuntu-optimize/archive/main.zip
unzip main.zip
cd ubuntu-optimize-main

# Make scripts executable
chmod +x ubuntu-optimize.sh
chmod +x scripts/*.sh

# Test installation
./ubuntu-optimize.sh status
```

### Core Optimization Modules
- **System Updates** - Complete system package updates and security patches
- **APT Cleanup** - Clean package cache, remove orphaned packages, update database
- **Cache Cleanup** - Clean user cache, thumbnails, trash, and temporary files
- **Snap Cleanup** - Remove old snap revisions and clean snap cache
- **Temporary Files** - Clean system temp directories and browser cache
- **Memory Optimization** - Clear memory caches and optimize RAM usage
- **Log Management** - Configure log rotation and limit log file sizes
- **SSD Optimization** - Enable TRIM, optimize I/O scheduler for SSDs
- **Tracker Disable** - Disable GNOME Tracker indexing for better performance
- **Preload Installation** - Install and configure preload for faster app startup

### Key Benefits
✅ **Safe & Non-destructive** - All operations designed for regular use  
✅ **Modular Design** - Run individual modules or complete optimization  
✅ **Intelligent Checks** - Automatic system detection and compatibility  
✅ **Detailed Feedback** - Comprehensive status reporting and error handling  
✅ **Backup Creation** - Automatic backups before major changes  
✅ **Root Safety** - Refuses to run as root for security  

## 📋 Requirements

- **OS**: Ubuntu LTS 18.04 or newer
- **Memory**: 1GB RAM minimum (2GB+ recommended for preload)
- **Disk**: 100MB free space for operations
- **Network**: Internet connection for system updates
- **Permissions**: User account with sudo privileges

## 🛠️ Installation

### Quick Installation (Recommended)
```bash
# Clone the repository
git clone https://github.com/dipto-roy/ubuntu-optimize.git
cd ubuntu-optimize

# Make all scripts executable
chmod +x ubuntu-optimize.sh
chmod +x scripts/*.sh

# Test the installation
./ubuntu-optimize.sh --help
```

### System-wide Installation
```bash
# After running the quick installation above
# Install the main script system-wide
sudo cp ubuntu-optimize.sh /usr/local/bin/ubuntu-optimize

# Install bash auto-completion
sudo cp ubuntu-optimize-autocomplete.sh /etc/bash_completion.d/ubuntu-optimize

# Reload bash completion (or restart terminal)
source /etc/bash_completion.d/ubuntu-optimize

# Now you can run from anywhere
ubuntu-optimize --help
```

### Manual Installation
```bash
# Download and extract (if git is not available)
wget https://github.com/dipto-roy/ubuntu-optimize/archive/main.zip
unzip main.zip
cd ubuntu-optimize-main

# Make scripts executable
chmod +x ubuntu-optimize.sh
chmod +x scripts/*.sh

# Test installation
./ubuntu-optimize.sh status
```

### One-liner Installation
```bash
# Quick setup with one command
curl -fsSL https://raw.githubusercontent.com/dipto-roy/ubuntu-optimize/main/install.sh | bash
```

### Installation Verification
After installation, verify everything is working correctly:

```bash
# Check if the main script is executable
./ubuntu-optimize.sh --help

# Test system status (safe command)
./ubuntu-optimize.sh status

# List all available modules
./ubuntu-optimize.sh list

# Check version information
./ubuntu-optimize.sh version
```

### Post-Installation Setup
```bash
# Optional: Add to PATH for easier access
echo 'export PATH="$HOME/ubuntu-optimize:$PATH"' >> ~/.bashrc
source ~/.bashrc

# Optional: Set up bash completion
source ubuntu-optimize-autocomplete.sh

# Optional: Create desktop shortcut
cat > ~/Desktop/ubuntu-optimize.desktop << EOF
[Desktop Entry]
Version=1.0
Type=Application
Name=Ubuntu Optimize
Comment=Ubuntu System Optimization Toolkit
Exec=$HOME/ubuntu-optimize/ubuntu-optimize.sh
Icon=utilities-system-monitor
Terminal=true
Categories=System;
EOF
chmod +x ~/Desktop/ubuntu-optimize.desktop
```

## 🎯 Usage

### Quick Start
```bash
# Run complete optimization
./ubuntu-optimize.sh full

# Show system status
./ubuntu-optimize.sh status

# List all available modules
./ubuntu-optimize.sh list
```

### Individual Modules
```bash
# System maintenance
./ubuntu-optimize.sh update              # Update system packages
./ubuntu-optimize.sh clean-apt           # Clean APT cache
./ubuntu-optimize.sh clean-cache         # Clean user cache
./ubuntu-optimize.sh clean-snap          # Clean snap packages
./ubuntu-optimize.sh clean-temp          # Clean temporary files

# Performance optimization
./ubuntu-optimize.sh ram-clean           # Clean memory
./ubuntu-optimize.sh trim-ssd            # Optimize SSD
./ubuntu-optimize.sh limit-logs          # Manage log files
./ubuntu-optimize.sh install-preload     # Install preload

# Optional optimizations
./ubuntu-optimize.sh disable-tracker     # Disable GNOME Tracker
```

### Command Options
```bash
# Available options
-v, --verbose     Enable verbose output
-q, --quiet       Suppress non-error output  
-y, --yes         Auto-answer yes to prompts
-h, --help        Show help message

# Examples
./ubuntu-optimize.sh full --verbose      # Verbose full optimization
./ubuntu-optimize.sh update --yes        # Update without prompts
./ubuntu-optimize.sh clean-cache -q      # Quiet cache cleanup
```

## 📁 Project Structure

```
ubuntu-optimize/
├── ubuntu-optimize.sh               # Main CLI entry point
├── ubuntu-optimize-autocomplete.sh  # Bash auto-completion
├── README.md                        # This documentation
└── scripts/
    ├── clean-apt.sh                 # APT package cleanup
    ├── clean-cache.sh               # User cache cleanup  
    ├── clean-snap.sh                # Snap package cleanup
    ├── clean-temp.sh                # Temporary files cleanup
    ├── disable-tracker.sh           # GNOME Tracker disable
    ├── install-preload.sh           # Preload installation
    ├── limit-logs.sh                # Log management
    ├── ram-clean.sh                 # Memory optimization
    ├── trim-ssd.sh                  # SSD optimization
    ├── update-system.sh             # System updates
    └── full-optimize.sh             # Complete optimization
```

## 🔧 Module Details

### System Updates (`update-system.sh`)
- Updates APT packages and security patches
- Updates Snap packages (if installed)
- Updates Flatpak packages (if installed)
- Checks for firmware updates
- Performs system maintenance tasks
- Checks for distribution upgrades

### APT Cleanup (`clean-apt.sh`)
- Cleans APT package cache
- Removes orphaned packages
- Updates package database
- Shows disk space recovered

### Cache Cleanup (`clean-cache.sh`)
- Cleans `~/.cache/*` (preserves important dirs)
- Cleans thumbnail cache
- Empties trash bin
- Removes temporary files in home directory

### Snap Cleanup (`clean-snap.sh`)
- Removes old snap revisions
- Cleans snap cache directories
- Refreshes snap store cache

### Temporary Files (`clean-temp.sh`)
- Cleans `/tmp` (preserves system files)
- Cleans `/var/tmp` 
- Cleans old log files
- Cleans browser temporary files

### Memory Optimization (`ram-clean.sh`)
- Clears page cache
- Clears dentries and inodes
- Optimizes swap usage
- Compacts memory
- Applies memory optimization settings

### Log Management (`limit-logs.sh`)
- Configures systemd journal limits
- Sets up log rotation
- Cleans large log files
- Configures automatic cleanup

### SSD Optimization (`trim-ssd.sh`)
- Detects SSD drives
- Runs manual TRIM
- Enables automatic TRIM scheduling
- Optimizes I/O scheduler for SSDs
- Shows SSD health information

### Tracker Disable (`disable-tracker.sh`)
- Stops GNOME Tracker services
- Disables autostart
- Masks systemd services
- Clears tracker database

### Preload Installation (`install-preload.sh`)
- Installs preload package
- Creates optimized configuration
- Enables and starts service
- Verifies installation

## 📊 System Status

Check your system status anytime:

```bash
./ubuntu-optimize.sh status
```

This shows:
- System information (OS, kernel, uptime)
- Memory usage
- Disk usage  
- Package information
- Optimization service status
- Last optimization date

## 🔒 Safety Features

### Root Protection
- Scripts refuse to run as root
- Requires user account with sudo privileges
- Prevents accidental system damage

### Backup Creation
- Creates system state backups before major changes
- Stores configuration backups
- Maintains optimization logs

### Intelligent Checks
- Detects system compatibility
- Checks available disk space
- Verifies internet connectivity
- Validates package integrity

### Error Handling
- Graceful error recovery
- Detailed error messages
- Safe failure modes
- User confirmation for risky operations

## 📈 Performance Impact

### Expected Results
- **Disk Space**: 500MB - 2GB freed (varies by system)
- **Memory Usage**: 50-200MB freed immediately
- **Boot Time**: 10-30% improvement (with preload)
- **App Startup**: 20-50% faster (with preload)
- **System Responsiveness**: Noticeable improvement

### Benchmark Example
```
Before Optimization:
- Available Memory: 1.2GB
- Free Disk Space: 15GB
- Boot Time: 45 seconds

After Optimization:
- Available Memory: 1.4GB (+200MB)
- Free Disk Space: 16.5GB (+1.5GB)
- Boot Time: 32 seconds (-13 seconds)
```

## 🔧 Advanced Configuration

### Custom Module Creation
Add your own optimization modules:

1. Create script in `scripts/` directory
2. Follow the naming convention: `module-name.sh`
3. Include proper error handling and status messages
4. Update the main script to recognize new module

### Scheduling Optimization
Set up automatic optimization:

```bash
# Add to crontab for weekly optimization
0 2 * * 0 /path/to/ubuntu-optimize.sh full -q -y
```

### Environment Variables
Customize behavior with environment variables:

```bash
export UBUNTU_OPTIMIZE_AUTO_YES="true"    # Auto-answer yes
export UBUNTU_OPTIMIZE_VERBOSE="true"     # Enable verbose mode
export UBUNTU_OPTIMIZE_QUIET="true"       # Enable quiet mode
```

## 🐛 Troubleshooting

### Common Issues

**Script won't run**
```bash
# Make executable
chmod +x ubuntu-optimize.sh
chmod +x scripts/*.sh
```

**Permission denied errors**
```bash
# Check sudo privileges
sudo -v

# Don't run as root
# Use your regular user account
```

**Network connectivity issues**
```bash
# Test internet connection
ping -c 3 8.8.8.8

# Check DNS resolution
nslookup ubuntu.com
```

**APT lock errors**
```bash
# Wait for other package managers to finish
# Or restart the system if necessary
sudo killall apt apt-get
sudo rm /var/lib/apt/lists/lock
sudo rm /var/cache/apt/archives/lock
sudo rm /var/lib/dpkg/lock*
sudo dpkg --configure -a
```

### Log Files
Check logs for detailed information:
```bash
# Optimization logs
ls ~/.ubuntu-optimize-logs/

# System logs
journalctl -f
tail -f /var/log/syslog
```

## 🤝 Contributing

We welcome contributions! Please see our contributing guidelines:

1. **Fork** the repository
2. **Create** a feature branch
3. **Test** your changes thoroughly
4. **Submit** a pull request

### Development Guidelines
- Follow existing code style
- Include comprehensive error handling
- Add status messages for user feedback
- Test on multiple Ubuntu versions
- Update documentation

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🙏 Acknowledgments

- Ubuntu community for optimization best practices
- Contributors and testers
- Open source tools and utilities used

## 📞 Support

- **Issues**: [GitHub Issues](https://github.com/dipto-roy/ubuntu-optimize/issues)
- **Discussions**: [GitHub Discussions](https://github.com/dipto-roy/ubuntu-optimize/discussions)
- **Documentation**: [Wiki](https://github.com/dipto-roy/ubuntu-optimize/wiki)
- **Source Code**: [Ubuntu Optimize Toolkit](https://github.com/dipto-roy/ubuntu-optimize)

## 🔄 Version History

### v1.0.0 (Current)
- Initial release
- Complete modular optimization system
- All core modules implemented
- Comprehensive documentation
- Safety features and error handling

---

**⭐ If this toolkit helped optimize your Ubuntu system, please star the repository!**
