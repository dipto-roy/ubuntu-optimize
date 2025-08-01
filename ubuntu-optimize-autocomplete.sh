#!/bin/bash
#
# ubuntu-optimize-autocomplete.sh - Bash auto-completion for ubuntu-optimize
# 
# This script provides bash auto-completion for the ubuntu-optimize command
# 
# Installation:
# 1. Copy this file to /etc/bash_completion.d/ubuntu-optimize
# 2. Or source it in your ~/.bashrc: source /path/to/ubuntu-optimize-autocomplete.sh
# 3. Restart your shell or run: source ~/.bashrc

_ubuntu_optimize_completion() {
    local cur prev opts base_command
    COMPREPLY=()
    cur="${COMP_WORDS[COMP_CWORD]}"
    prev="${COMP_WORDS[COMP_CWORD-1]}"
    base_command="${COMP_WORDS[0]}"
    
    # All available commands - complete list from ubuntu-optimize.sh
    local main_commands="full update clean-apt clean-cache clean-snap clean-temp ram-clean limit-logs trim-ssd disable-tracker install-preload status list version help"
    
    # All available options
    local options="-v --verbose -q --quiet -y --yes -h --help"
    
    # System maintenance commands
    local maintenance_commands="update clean-apt clean-cache clean-snap clean-temp"
    
    # Performance optimization commands
    local performance_commands="ram-clean trim-ssd limit-logs install-preload"
    
    # Optional/advanced commands
    local optional_commands="disable-tracker"
    
    # Information commands
    local info_commands="status list version help"
    
    case "${prev}" in
        ubuntu-optimize.sh|ubuntu-optimize)
            # On the main command, complete with all commands and global options
            COMPREPLY=( $(compgen -W "${main_commands} ${options}" -- "${cur}") )
            return 0
            ;;
        # For any optimization command, offer available options
        full|update|clean-apt|clean-cache|clean-snap|clean-temp|ram-clean|limit-logs|trim-ssd|disable-tracker|install-preload)
            COMPREPLY=( $(compgen -W "${options}" -- "${cur}") )
            return 0
            ;;
        # For info commands, no additional completion needed
        status|list|version|help)
            return 0
            ;;
        # For options that expect no parameters, complete with other options or commands
        -v|--verbose|-q|--quiet|-y|--yes|-h|--help)
            # Check if we already have a command
            local has_command=""
            for word in "${COMP_WORDS[@]:1}"; do
                if [[ " ${main_commands} " == *" ${word} "* ]]; then
                    has_command="$word"
                    break
                fi
            done
            
            if [[ -n "$has_command" ]]; then
                # Already have a command, complete with remaining options
                COMPREPLY=( $(compgen -W "${options}" -- "${cur}") )
            else
                # No command yet, complete with commands and options
                COMPREPLY=( $(compgen -W "${main_commands} ${options}" -- "${cur}") )
            fi
            return 0
            ;;
        *)
            # Default case: complete with commands and options
            COMPREPLY=( $(compgen -W "${main_commands} ${options}" -- "${cur}") )
            return 0
            ;;
    esac
}

# Register the completion function
complete -F _ubuntu_optimize_completion ubuntu-optimize.sh
complete -F _ubuntu_optimize_completion ubuntu-optimize

# If ubuntu-optimize is installed system-wide, also complete for it
if command -v ubuntu-optimize &> /dev/null; then
    complete -F _ubuntu_optimize_completion ubuntu-optimize
fi
