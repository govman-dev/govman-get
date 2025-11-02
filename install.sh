#!/bin/bash

# Govman Installation Script
# This script installs the Govman Go Version Manager

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Global variables
OS=""
ARCH=""
BINARY_NAME=""
GOVMAN_HOME=""
SHELL_RC=""
USER_SHELL=""

# Print colorized message
info() {
    echo -e "${BLUE}INFO:${NC} $1"
}

success() {
    echo -e "${GREEN}SUCCESS:${NC} $1"
}

error() {
    echo -e "${RED}ERROR:${NC} $1"
    exit 1
}

# Detect OS and architecture
detect_os_arch() {
    OS="$(uname -s | tr '[:upper:]' '[:lower:]')"
    ARCH="$(uname -m)"
    
    case "$ARCH" in
        x86_64) ARCH="amd64" ;;
        aarch64) ARCH="arm64" ;;
        armv7l) ARCH="arm" ;;
    esac
    
    BINARY_NAME="govman-${OS}-${ARCH}"
}

# Detect user's actual shell
detect_user_shell() {
    # Get the user's default shell from $SHELL environment variable
    USER_SHELL=$(basename "$SHELL")
    
    case "$USER_SHELL" in
        bash)
            SHELL_RC="$HOME/.bashrc"
            # On macOS, also check .bash_profile
            if [[ "$OS" == "darwin" ]] && [[ -f "$HOME/.bash_profile" ]]; then
                SHELL_RC="$HOME/.bash_profile"
            fi
            ;;
        zsh)
            SHELL_RC="$HOME/.zshrc"
            ;;
        fish)
            SHELL_RC="$HOME/.config/fish/config.fish"
            ;;
        *)
            # Try to detect based on existing files
            if [[ -f "$HOME/.zshrc" ]]; then
                SHELL_RC="$HOME/.zshrc"
                USER_SHELL="zsh"
            elif [[ -f "$HOME/.bashrc" ]]; then
                SHELL_RC="$HOME/.bashrc"
                USER_SHELL="bash"
            elif [[ -f "$HOME/.bash_profile" ]]; then
                SHELL_RC="$HOME/.bash_profile"
                USER_SHELL="bash"
            else
                # Default to .bashrc if nothing found
                SHELL_RC="$HOME/.bashrc"
                USER_SHELL="bash"
            fi
            ;;
    esac
    
    info "Detected shell: $USER_SHELL"
    info "Configuration file: $SHELL_RC"
}

# Setup directories
setup_directories() {
    GOVMAN_HOME="${HOME}/.govman"
    mkdir -p "${GOVMAN_HOME}/"{bin,versions,cache}
    
    # Detect user's shell
    detect_user_shell
}

# Download and install binary
install_binary() {
    LATEST_RELEASE_URL="https://api.github.com/repos/justjundana/govman/releases/latest"
    DOWNLOAD_URL=$(curl -s "$LATEST_RELEASE_URL" | grep "browser_download_url.*${BINARY_NAME}" | cut -d '"' -f 4)
    
    if [ -z "$DOWNLOAD_URL" ]; then
        error "Could not find binary for your platform: ${OS}/${ARCH}"
    fi
    
    info "Downloading Govman..."
    curl -L "$DOWNLOAD_URL" -o "${GOVMAN_HOME}/bin/govman"
    chmod +x "${GOVMAN_HOME}/bin/govman"
}

# Initialize Govman
initialize_govman() {
    info "Initializing Govman..."
    "${GOVMAN_HOME}/bin/govman" init --force
}

# Main installation
main() {
    info "Installing Govman..."
    
    detect_os_arch
    setup_directories
    install_binary
    initialize_govman
    
    success "Govman has been installed successfully!"
    success "Please restart your terminal or run: source $SHELL_RC"
    info "Run 'govman --help' to get started"
}

main