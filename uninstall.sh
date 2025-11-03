#!/bin/bash

# Govman Uninstallation Script
# This script removes Govman and its associated files

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
    
    # Method 2: Check if running in Homebrew's Ruby environment
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
        warning "Govman directory not found (${GOVMAN_HOME}), skipping removal"
        return 0
    fi
    
    info "Removing Govman installation directory..."
    rm -rf "$GOVMAN_HOME" || warning "Failed to remove some Govman files"
}

# Remove GOVMAN configuration block from shell config files
remove_shell_config() {
    local shell_files=("$HOME/.bashrc" "$HOME/.bash_profile" "$HOME/.profile" "$HOME/.zshrc" "$HOME/.config/fish/config.fish")
    
    info "Removing shell configurations..."
    for config_file in "${shell_files[@]}"; do
        if [ -f "$config_file" ]; then
            info "Cleaning up $config_file..."
            
            # Use perl for cross-platform compatibility
            perl -i.bak -ne '
                BEGIN { $skip = 0; }
                if (/^# GOVMAN - Go Version Manager$/) { 
                    $skip = 1; 
                    next; 
                }
                if (/^# END GOVMAN$/) { 
                    $skip = 0; 
                    next; 
                }
                print unless $skip;
            ' "$config_file" 2>/dev/null || {
                # Fallback to awk if perl fails
                awk '/^# GOVMAN - Go Version Manager$/{p=1;next}/^# END GOVMAN$/{p=0;next}!p' "$config_file" > "${config_file}.tmp" && \
                mv "${config_file}.tmp" "$config_file"
            }
            
            # Clean up backup file
            rm -f "${config_file}.bak"
            
            # Remove trailing empty lines (cross-platform)
            perl -i -pe 'chomp if eof' "$config_file" 2>/dev/null || true
        fi
    done
}

# Remove PATH entry from shell RC files
cleanup_shell_rc() {
    local RC_FILES=("$HOME/.bashrc" "$HOME/.zshrc" "$HOME/.profile")
    
    info "Cleaning up additional shell configurations..."
    for RC_FILE in "${RC_FILES[@]}"; do
        if [ -f "$RC_FILE" ]; then
            # Use perl for cross-platform compatibility
            perl -i.bak -ne 'print unless /export PATH="\$HOME\/\.govman\/bin:\$PATH"/' "$RC_FILE" 2>/dev/null || {
                # Fallback to sed with platform detection
                if [[ "$OSTYPE" == "darwin"* ]]; then
                    sed -i '' '/export PATH="\$HOME\/.govman\/bin:\$PATH"/d' "$RC_FILE"
                else
                    sed -i '/export PATH="\$HOME\/.govman\/bin:\$PATH"/d' "$RC_FILE"
                fi
            }
            rm -f "${RC_FILE}.bak"
        fi
    done
}

# Main uninstallation
main() {
    info "Uninstalling Govman..."
    
    remove_govman
    remove_shell_config
    cleanup_shell_rc
    
    success "Govman has been uninstalled successfully!"
    success "Shell configurations have been cleaned up"
    info "Please restart your terminal or run: source ~/.bashrc (or ~/.zshrc)"
}

# Determine if confirmation is needed
if is_homebrew; then
    # Running via Homebrew - no confirmation needed
    info "Detected Homebrew uninstallation - proceeding without confirmation"
    main
else
    # Running manually - ask for confirmation
    warning "This will remove Govman and all installed Go versions."
    
    # Read from /dev/tty to handle piped input (curl | bash)
    if [ -t 0 ]; then
        # stdin is a terminal - read normally
        read -p "Are you sure you want to continue? [y/N] " -n 1 -r
    else
        # stdin is piped - read from /dev/tty and print prompt to stderr
        printf "Are you sure you want to continue? [y/N] " >&2
        read -n 1 -r < /dev/tty
    fi
    
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        main
    else
        info "Uninstallation cancelled"
        exit 0
    fi
fi