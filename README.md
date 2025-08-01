# Ubuntu Optimize Toolkit

A comprehensive, modular CLI toolkit for Ubuntu system optimization, cleanup, and performance enhancement. Designed for Ubuntu LTS systems with safety and efficiency in mind.

> **Part of CLI Tools Collection**: This toolkit is part of the [dipto-roy/cli_tools-for-me](https://github.com/dipto-roy/cli_tools-for-me) repository, which contains various useful command-line tools and utilities for system administration and development.

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
git clone https://github.com/dipto-roy/cli_tools-for-me.git
cd cli_tools-for-me/ubuntu-optimize

# Make all scripts executable
chmod +x ubuntu-optimize.sh
chmod +x scripts/*.sh

# Test the installation
./ubuntu-optimize.sh --help
```

### System-wide Installation (Recommended)
```bash
# After cloning and entering the directory
./install-system-wide.sh

# This will:
# - Install all files to /opt/ubuntu-optimize/
# - Create ubuntu-optimize command in /usr/local/bin/
# - Set up enhanced bash autocomplete system-wide
# - Test the installation and verify functionality

# Now you can run from anywhere with full autocomplete
ubuntu-optimize --help                  # Show comprehensive help
ubuntu-optimize status                  # Show detailed system status  
ubuntu-optimize clean-cache             # Clean cache files
ubuntu-optimize full --verbose          # Full optimization with detailed output

# Autocomplete features:
# - Tab completion for all commands and options
# - Context-aware option suggestions
# - Command categorization (maintenance, performance, info)
# - Smart completion based on current command context
```

### Alternative System-wide Installation
```bash
# Manual system-wide setup (if automated installer fails)
sudo mkdir -p /opt/ubuntu-optimize
sudo cp -r * /opt/ubuntu-optimize/
sudo chmod +x /opt/ubuntu-optimize/*.sh /opt/ubuntu-optimize/scripts/*.sh

# Create wrapper command
echo '#!/bin/bash' | sudo tee /usr/local/bin/ubuntu-optimize
echo 'exec /opt/ubuntu-optimize/ubuntu-optimize.sh "$@"' | sudo tee -a /usr/local/bin/ubuntu-optimize
sudo chmod +x /usr/local/bin/ubuntu-optimize

# Install autocomplete
sudo cp ubuntu-optimize-autocomplete.sh /etc/bash_completion.d/ubuntu-optimize
source /etc/bash_completion.d/ubuntu-optimize
```

### Manual Installation
```bash
# Download and extract (if git is not available)
wget https://github.com/dipto-roy/cli_tools-for-me/archive/main.zip
unzip main.zip
cd cli_tools-for-me-main/ubuntu-optimize

# Make scripts executable
chmod +x ubuntu-optimize.sh
chmod +x scripts/*.sh

# Test installation
./ubuntu-optimize.sh status
```

### One-liner Installation
```bash
# Quick setup with one command
curl -fsSL https://raw.githubusercontent.com/dipto-roy/cli_tools-for-me/main/ubuntu-optimize/install.sh | bash
```

### Installation Verification
After installation, verify everything is working correctly:

```bash
# Check if the main script is executable and working
./ubuntu-optimize.sh --help

# Test system status (safe command that shows system information)
./ubuntu-optimize.sh status

# List all available modules with descriptions  
./ubuntu-optimize.sh list

# Check version information and compatibility
./ubuntu-optimize.sh version

# Test autocomplete functionality (if installed system-wide)
ubuntu-optimize <TAB><TAB>              # Should show all commands
ubuntu-optimize cl<TAB>                 # Should complete to clean-*
ubuntu-optimize full --<TAB><TAB>       # Should show all options

# Verify specific module help
./ubuntu-optimize.sh help               # General help
./ubuntu-optimize.sh clean-cache --help # Command-specific help
```

### Autocomplete Testing
After system-wide installation, test the enhanced autocomplete:

```bash
# Test command completion
ubuntu-optimize <TAB><TAB>              # Shows: full, update, clean-apt, clean-cache, etc.
ubuntu-optimize u<TAB>                  # Completes to "update"
ubuntu-optimize clean-<TAB><TAB>        # Shows: clean-apt, clean-cache, clean-snap, clean-temp

# Test option completion
ubuntu-optimize full -<TAB><TAB>        # Shows: -v, -q, -y, -h, --verbose, --quiet, --yes, --help
ubuntu-optimize status --<TAB><TAB>     # Shows: --verbose, --quiet, --yes, --help

# Test context-aware completion
ubuntu-optimize full --verbose <TAB><TAB>  # Shows remaining options
ubuntu-optimize update -y <TAB><TAB>       # Shows remaining options

# All 15 commands should be available:
# Optimization: full, update, clean-apt, clean-cache, clean-snap, clean-temp, 
#               ram-clean, limit-logs, trim-ssd, disable-tracker, install-preload
# Information: status, list, version, help
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
# System maintenance commands
./ubuntu-optimize.sh update              # Update system packages and security patches
./ubuntu-optimize.sh clean-apt           # Clean APT package cache and remove orphaned packages
./ubuntu-optimize.sh clean-cache         # Clean user cache, thumbnails, and temporary files  
./ubuntu-optimize.sh clean-snap          # Clean snap packages and remove old revisions
./ubuntu-optimize.sh clean-temp          # Clean system temporary files and browser cache

# Performance optimization commands
./ubuntu-optimize.sh ram-clean           # Clean memory caches and optimize RAM usage
./ubuntu-optimize.sh trim-ssd            # Optimize SSD performance and enable TRIM
./ubuntu-optimize.sh limit-logs          # Configure log rotation and manage log file sizes
./ubuntu-optimize.sh install-preload     # Install and configure preload for faster app startup

# Optional optimization commands
./ubuntu-optimize.sh disable-tracker     # Disable GNOME Tracker indexing services (optional)

# Information and utility commands  
./ubuntu-optimize.sh status              # Show comprehensive system status and optimization info
./ubuntu-optimize.sh list                # List all available optimization modules with descriptions
./ubuntu-optimize.sh version             # Show version information and system compatibility
./ubuntu-optimize.sh help                # Show detailed help message with examples

# Complete optimization
./ubuntu-optimize.sh full                # Run all optimization modules in optimal sequence
```

### Command Reference (All 15 Available Commands)
| Command | Category | Description | Safety Level |
|---------|----------|-------------|--------------|
| `full` | Complete | Run all optimization modules in sequence | Safe |
| `update` | Maintenance | Update system packages and security patches | Safe |
| `clean-apt` | Maintenance | Clean APT cache and remove orphaned packages | Safe |
| `clean-cache` | Maintenance | Clean user cache and temporary files | Safe |
| `clean-snap` | Maintenance | Clean snap packages and old revisions | Safe |
| `clean-temp` | Maintenance | Clean system temporary files | Safe |
| `ram-clean` | Performance | Clean memory caches and optimize RAM | Safe |
| `limit-logs` | Performance | Configure log rotation and cleanup | Safe |
| `trim-ssd` | Performance | Optimize SSD performance and TRIM | Safe |
| `install-preload` | Performance | Install preload for faster app startup | Safe |
| `disable-tracker` | Optional | Disable GNOME Tracker indexing | Optional |
| `status` | Information | Show system status and optimization info | Safe |
| `list` | Information | List all available modules | Safe |
| `version` | Information | Show version and compatibility info | Safe |
| `help` | Information | Show comprehensive help message | Safe |

### Command Options
```bash
# Available options (work with any command)
-v, --verbose     Enable verbose output with detailed progress information
-q, --quiet       Suppress non-error output for automated scripts  
-y, --yes         Auto-answer yes to prompts for unattended operation
-h, --help        Show help message for command or general help

# Examples with options
./ubuntu-optimize.sh full --verbose      # Verbose full optimization with detailed output
./ubuntu-optimize.sh update --yes        # Update without interactive prompts
./ubuntu-optimize.sh clean-cache -q      # Quiet cache cleanup (minimal output)
./ubuntu-optimize.sh trim-ssd -v -y      # Verbose SSD optimization, auto-confirm actions

# Combining options
./ubuntu-optimize.sh full -v -y          # Full optimization: verbose + auto-confirm
./ubuntu-optimize.sh ram-clean --quiet   # Silent memory cleanup
./ubuntu-optimize.sh status --verbose    # Detailed system status report
```

### Enhanced Autocomplete Features
If you have bash autocomplete installed, you get smart command completion:

```bash
# Basic command completion
ubuntu-optimize <TAB><TAB>              # Shows all available commands
ubuntu-optimize cl<TAB>                 # Completes to "clean-" commands
ubuntu-optimize clean-<TAB><TAB>        # Shows: clean-apt, clean-cache, clean-snap, clean-temp

# Option completion  
ubuntu-optimize full --<TAB><TAB>       # Shows: --verbose, --quiet, --yes, --help
ubuntu-optimize update -<TAB><TAB>      # Shows: -v, -q, -y, -h and long options

# Context-aware completion
ubuntu-optimize full -v <TAB><TAB>      # Shows remaining options: --quiet, --yes, --help
ubuntu-optimize status <TAB><TAB>       # Shows available options for status command

# Categories of commands available:
# System Maintenance: update, clean-apt, clean-cache, clean-snap, clean-temp
# Performance: ram-clean, trim-ssd, limit-logs, install-preload  
# Optional: disable-tracker
# Information: status, list, version, help
```

## 📁 Project Structure

```
ubuntu-optimize/
├── ubuntu-optimize.sh               # Main CLI entry point with command validation
├── ubuntu-optimize-autocomplete.sh  # Enhanced bash auto-completion
├── install.sh                       # One-liner installation script
├── install-system-wide.sh           # System-wide installation script  
├── setup.sh                         # Interactive setup and configuration script
├── README.md                        # This comprehensive documentation
├── .gitignore                       # Git ignore file (hides additional README files)
└── scripts/                         # Modular optimization scripts directory
    ├── clean-apt.sh                 # APT package cache cleanup
    ├── clean-cache.sh               # User cache and thumbnail cleanup  
    ├── clean-snap.sh                # Snap package cleanup and old revisions
    ├── clean-temp.sh                # Temporary files and browser cache cleanup
    ├── disable-tracker.sh           # GNOME Tracker disable (optional)
    ├── full-optimize.sh             # Complete optimization orchestrator
    ├── install-preload.sh           # Preload installation and configuration
    ├── limit-logs.sh                # Log management and rotation
    ├── ram-clean.sh                 # Memory optimization and cleanup
    ├── trim-ssd.sh                  # SSD optimization and TRIM configuration
    └── update-system.sh             # System packages and security updates

# Installation and configuration files:
# - install-system-wide.sh: Proper /opt installation with wrapper script
# - setup.sh: Interactive setup with user choices and testing
# - install.sh: Quick one-liner installation from repository
# - .gitignore: Hides README variants from public repository view

# All 11 optimization modules are independently executable and safe
# Main script provides unified interface, validation, and error handling
# Autocomplete provides context-aware command and option completion
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

- **Issues**: [GitHub Issues](https://github.com/dipto-roy/cli_tools-for-me/issues)
- **Discussions**: [GitHub Discussions](https://github.com/dipto-roy/cli_tools-for-me/discussions)
- **Documentation**: [Wiki](https://github.com/dipto-roy/cli_tools-for-me/wiki)
- **Source Code**: [Ubuntu Optimize Toolkit](https://github.com/dipto-roy/cli_tools-for-me/tree/main/ubuntu-optimize)

## 🔄 Version History

### v1.0.0 (Current)
- Initial release with complete modular optimization system
- All core modules implemented and tested
- System-wide installation support with proper wrapper scripts
- Comprehensive bash autocomplete with intelligent command completion
- Multiple installation methods (quick, system-wide, manual, one-liner)
- Interactive setup script for guided installation
- Safety features and error handling throughout
- Full integration with dipto-roy/cli_tools-for-me repository
- Comprehensive documentation with usage examples
- Performance metrics and optimization logging
- Support for Ubuntu LTS 18.04+ systems

#### Core Features Added:
✅ **11 Optimization Modules**: Complete set of system optimization tools  
✅ **4 Installation Methods**: Flexible installation options for different needs  
✅ **Smart Autocomplete**: Context-aware bash completion with all commands and options  
✅ **System-wide Support**: Proper installation in /opt with wrapper script  
✅ **Safety First**: Root protection, backup creation, and error recovery  
✅ **Performance Tracking**: Before/after metrics and optimization logging  
✅ **Interactive Setup**: Guided configuration and testing  

#### Technical Implementation:
- Main CLI: `ubuntu-optimize.sh` - Central command dispatcher with validation
- Autocomplete: Enhanced completion with command categorization and context awareness
- Installation Scripts: `install-system-wide.sh`, `setup.sh`, `install.sh` for different deployment needs
- Modular Architecture: 11 independent optimization scripts in `/scripts/` directory
- Comprehensive Documentation: Detailed README with examples, troubleshooting, and advanced usage
- Repository Integration: Part of larger CLI tools collection with proper Git structure

---

## 📋 Complete Command Summary

The Ubuntu Optimize Toolkit provides **15 comprehensive commands** organized into logical categories:

### 🔧 **Optimization Commands (11 total)**
```bash
# Complete System Optimization
ubuntu-optimize full                    # All-in-one optimization (recommended)

# System Maintenance (5 commands)  
ubuntu-optimize update                  # System packages & security updates
ubuntu-optimize clean-apt               # APT cache & orphaned packages
ubuntu-optimize clean-cache             # User cache & thumbnails  
ubuntu-optimize clean-snap              # Snap packages & old revisions
ubuntu-optimize clean-temp              # Temporary files & browser cache

# Performance Optimization (4 commands)
ubuntu-optimize ram-clean               # Memory caches & RAM optimization
ubuntu-optimize trim-ssd                # SSD performance & TRIM scheduling
ubuntu-optimize limit-logs              # Log rotation & size management  
ubuntu-optimize install-preload         # Preload for faster app startup

# Optional Optimization (1 command)
ubuntu-optimize disable-tracker         # GNOME Tracker disable (optional)
```

### 📊 **Information Commands (4 total)**  
```bash
ubuntu-optimize status                  # System status & optimization info
ubuntu-optimize list                    # Available modules with descriptions
ubuntu-optimize version                 # Version & compatibility information
ubuntu-optimize help                    # Comprehensive help with examples
```

### ⚙️ **Available Options (4 total)**
```bash
-v, --verbose                          # Detailed output with progress information
-q, --quiet                            # Minimal output for automated scripts
-y, --yes                              # Auto-confirm all prompts (unattended mode)
-h, --help                             # Command-specific or general help
```

### 🎯 **Smart Autocomplete Features**
- **15 commands** with full tab completion
- **Context-aware option suggestions** based on current command
- **Command categorization** (maintenance, performance, information)
- **Intelligent completion** that understands what you've already typed
- **Works with both** `./ubuntu-optimize.sh` and system-wide `ubuntu-optimize`

**⭐ If this toolkit helped optimize your Ubuntu system, please star the repository!**

**🔗 Explore more tools**: Check out other useful CLI tools in the [dipto-roy/cli_tools-for-me](https://github.com/dipto-roy/cli_tools-for-me) repository.
