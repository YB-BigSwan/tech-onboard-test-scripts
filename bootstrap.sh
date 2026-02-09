#!/bin/bash

# MacOS Developer Environment Bootstrap Script
# This script sets up a complete development environment on a fresh Mac

set -e  # Exit on any error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Logging functions
log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_step() {
    echo -e "${BLUE}[STEP]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if running on macOS
if [[ "$(uname)" != "Darwin" ]]; then
    log_error "This script is only for macOS"
    exit 1
fi

log_info "Starting MacOS Developer Environment Setup..."
log_info "This will take 15-30 minutes depending on your internet connection"
echo ""

# Get the directory where this script is located
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# Step 1: Install Homebrew if not already installed
log_step "Step 1/7: Checking Homebrew installation..."
if ! command -v brew &> /dev/null; then
    log_info "Installing Homebrew..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    
    # Add Homebrew to PATH for Apple Silicon Macs
    if [[ $(uname -m) == 'arm64' ]]; then
        echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> ~/.zprofile
        eval "$(/opt/homebrew/bin/brew shellenv)"
    fi
else
    log_info "Homebrew already installed"
    brew update
fi
echo ""

# Step 2: Install CLI packages
log_step "Step 2/7: Installing CLI packages..."

# Core utilities
log_info "Installing core utilities..."
brew install coreutils binutils diffutils gnutls jq bazelisk

# Development tools
log_info "Installing development tools..."
brew install gcc parallel make gnu-sed graphviz python-yq

# Programming languages and tools
log_info "Installing programming languages and cloud tools..."
brew install git go docker docker-compose kubectl openblas node helm terraform hcl2json gh

# Python
log_info "Installing Python..."
brew install python@3.11

log_info "CLI packages installation complete"
echo ""

# Step 3: Install GUI applications
log_step "Step 3/7: Installing GUI applications..."

log_info "Installing Visual Studio Code..."
brew install --cask visual-studio-code

log_info "Installing iTerm2..."
brew install --cask iterm2

log_info "Installing Docker Desktop..."
brew install --cask docker

log_info "Installing Tailscale..."
brew install --cask tailscale

log_info "Installing Google Cloud SDK..."
brew install --cask google-cloud-sdk

log_info "GUI applications installation complete"
echo ""

# Step 4: Install gcloud components
log_step "Step 4/7: Installing gcloud components..."
if command -v gcloud &> /dev/null; then
    log_info "Installing gke-gcloud-auth-plugin..."
    gcloud components install gke-gcloud-auth-plugin --quiet || log_warn "Failed to install gke-gcloud-auth-plugin"
fi
echo ""

# Step 5: Install Oh My Zsh
log_step "Step 5/7: Setting up Oh My Zsh..."
if [[ ! -d "$HOME/.oh-my-zsh" ]]; then
    log_info "Installing Oh My Zsh..."
    sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
else
    log_info "Oh My Zsh already installed"
fi

# Install zsh plugins
log_info "Installing zsh plugins..."
ZSH_CUSTOM="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}"

# zsh-syntax-highlighting
if [[ ! -d "$ZSH_CUSTOM/plugins/zsh-syntax-highlighting" ]]; then
    git clone https://github.com/zsh-users/zsh-syntax-highlighting.git "$ZSH_CUSTOM/plugins/zsh-syntax-highlighting"
else
    log_info "zsh-syntax-highlighting already installed"
fi

# zsh-autosuggestions
if [[ ! -d "$ZSH_CUSTOM/plugins/zsh-autosuggestions" ]]; then
    git clone https://github.com/zsh-users/zsh-autosuggestions "$ZSH_CUSTOM/plugins/zsh-autosuggestions"
else
    log_info "zsh-autosuggestions already installed"
fi
echo ""

# Step 6: Setup dotfiles (symlinks)
log_step "Step 6/7: Setting up dotfiles..."
if [[ -d "$SCRIPT_DIR/dotfiles" ]]; then
    for file in "$SCRIPT_DIR/dotfiles"/.??*; do
        [[ "$(basename "$file")" == ".git" ]] && continue
        [[ "$(basename "$file")" == ".DS_Store" ]] && continue
        
        filename=$(basename "$file")
        target="$HOME/$filename"
        
        # Backup existing file if it exists and is not a symlink
        if [[ -f "$target" && ! -L "$target" ]]; then
            log_warn "Backing up existing $filename to ${filename}.backup"
            mv "$target" "${target}.backup"
        fi
        
        # Create symlink
        log_info "Symlinking $filename"
        ln -sf "$file" "$target"
    done
else
    log_warn "dotfiles directory not found, skipping..."
fi
echo ""

# Step 7: Install VS Code extensions
log_step "Step 7/7: Installing VS Code extensions..."
if command -v code &> /dev/null && [[ -f "$SCRIPT_DIR/vscode_extensions.txt" ]]; then
    while IFS= read -r extension || [[ -n "$extension" ]]; do
        [[ -z "$extension" || "$extension" =~ ^#.* ]] && continue
        
        log_info "Installing VS Code extension: $extension"
        code --install-extension "$extension" --force || log_warn "Failed to install $extension, continuing..."
    done < "$SCRIPT_DIR/vscode_extensions.txt"
else
    if ! command -v code &> /dev/null; then
        log_warn "VS Code 'code' command not found. After installing VS Code, run 'Shell Command: Install code command in PATH' from VS Code Command Palette"
    fi
fi
echo ""

# Install SnowSQL manually (not available via Homebrew)
log_info "Installing SnowSQL..."
if [[ ! -f /Applications/SnowSQL.app/Contents/MacOS/snowsql ]]; then
    log_info "Downloading SnowSQL installer..."
    curl -O https://sfc-repo.snowflakecomputing.com/snowsql/bootstrap/1.2/darwin_x86_64/snowsql-1.2.28-darwin_x86_64.pkg
    log_info "Installing SnowSQL (may require password)..."
    sudo installer -pkg snowsql-1.2.28-darwin_x86_64.pkg -target /
    rm snowsql-1.2.28-darwin_x86_64.pkg
else
    log_info "SnowSQL already installed"
fi
echo ""

log_info "=========================================="
log_info "Setup Complete! 🎉"
log_info "=========================================="
echo ""
log_info "Next steps:"
log_info "1. Restart your terminal or run: source ~/.zshrc"
log_info "2. Configure your Git credentials if not already set:"
log_info "   git config --global user.name 'Your Name'"
log_info "   git config --global user.email 'your.email@example.com'"
log_info "3. Sign in to services:"
log_info "   - Docker Desktop (open the app)"
log_info "   - gcloud: gcloud auth login"
log_info "   - GitHub: gh auth login"
log_info "   - Tailscale: sudo tailscale up"
log_info "4. Add your SSH keys to ~/.ssh/ (not included in this repo for security)"
log_info "5. Configure SnowSQL: snowsql -a <account> -u <username>"
echo ""
log_info "Note: Some applications may require a restart to work properly"
echo ""