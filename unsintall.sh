#!/bin/bash

# Govman Uninstallation Script
# This script removes Govman and its associated files

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[0;33m'
NC='\033[0m' # No Color

# Print colorized message
info() {
    echo -e "${BLUE}INFO:${NC} $1"
}

success() {
    echo -e "${GREEN}SUCCESS:${NC} $1"
}

warning() {
    echo -e "${YELLOW}WARNING:${NC} $1"
}

error() {
    echo -e "${RED}ERROR:${NC} $1"
    exit 1
}

# Check if running via Homebrew
is_homebrew() {
    # Method 1: Check HOMEBREW environment variables
    if [[ -n "$HOMEBREW_PREFIX" ]] || [[ -n "$HOMEBREW_CELLAR" ]] || [[ -n "$HOMEBREW_REPOSITORY" ]]; then
        return 0
    fi
    
    # Method 2: Check if parent process is brew
    if command -v brew &> /dev/null; then
        local parent_cmd=$(ps -o comm= $PPID 2>/dev/null)
        if [[ "$parent_cmd" == *"brew"* ]] || [[ "$parent_cmd" == *"ruby"* ]]; then
            return 0
        fi
    fi
    
    # Method 3: Check if running in Homebrew's Ruby environment
    if [[ "$0" == *"/Homebrew/"* ]] || [[ "$PWD" == *"/Homebrew/"* ]]; then
        return 0
    fi
    
    return 1
}

# Remove Govman directories and files
remove_govman() {
    GOVMAN_HOME="${HOME}/.govman"
    
    # Check if Govman is installed
    if [ ! -d "$GOVMAN_HOME" ]; then
        error "Govman does not appear to be installed (${GOVMAN_HOME} not found)"
    fi
    
    info "Removing Govman installation directory..."
    rm -rf "$GOVMAN_HOME"
}

# Remove GOVMAN configuration block from shell config files
remove_shell_config() {
    local shell_files=("$HOME/.bashrc" "$HOME/.bash_profile" "$HOME/.profile" "$HOME/.zshrc" "$HOME/.config/fish/config.fish")
    
    info "Removing shell configurations..."
    for config_file in "${shell_files[@]}"; do
        if [ -f "$config_file" ]; then
            info "Cleaning up $config_file..."
            local tmp_file="${config_file}.tmp"
            awk '/^# GOVMAN - Go Version Manager$/{p=1;next}/^# END GOVMAN$/{p=0;next}!p' "$config_file" > "$tmp_file"
            mv "$tmp_file" "$config_file"
            # Remove any empty lines at the end of file
            sed -i.bak -e :a -e '/^\n*$/{$d;N;ba' -e '}' "$config_file"
            rm -f "${config_file}.bak"
        fi
    done
}

# Remove PATH entry from shell RC files
cleanup_shell_rc() {
    local RC_FILES=("$HOME/.bashrc" "$HOME/.zshrc" "$HOME/.profile")
    
    info "Cleaning up shell configuration..."
    for RC_FILE in "${RC_FILES[@]}"; do
        if [ -f "$RC_FILE" ]; then
            sed -i.bak '/export PATH="\$HOME\/.govman\/bin:\$PATH"/d' "$RC_FILE"
            rm -f "${RC_FILE}.bak"
        fi
    done
}

# Main uninstallation
main() {
    info "Uninstalling Govman..."
    
    remove_govman
    remove_shell_config
    
    success "Govman has been uninstalled successfully!"
    success "Shell configurations have been cleaned up"
    info "Please restart your terminal for the changes to take effect"
}

# Determine if confirmation is needed
if is_homebrew; then
    # Running via Homebrew - no confirmation needed
    info "Detected Homebrew uninstallation - proceeding without confirmation"
    main
else
    # Running manually - ask for confirmation
    warning "This will remove Govman and all installed Go versions."
    read -p "Are you sure you want to continue? [y/N] " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        main
    else
        info "Uninstallation cancelled"
        exit 0
    fi
fi