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
    local cur prev opts
    COMPREPLY=()
    cur="${COMP_WORDS[COMP_CWORD]}"
    prev="${COMP_WORDS[COMP_CWORD-1]}"
    
    # Main commands
    opts="full update clean-apt clean-cache clean-snap clean-temp ram-clean limit-logs trim-ssd disable-tracker install-preload status list version help"
    
    # Options
    local options="-v --verbose -q --quiet -y --yes -h --help"
    
    case "${prev}" in
        ubuntu-optimize.sh|ubuntu-optimize)
            # Complete main commands and options
            COMPREPLY=( $(compgen -W "${opts} ${options}" -- "${cur}") )
            return 0
            ;;
        *)
            # For other cases, complete options
            COMPREPLY=( $(compgen -W "${options}" -- "${cur}") )
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
