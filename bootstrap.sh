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

echo "Starting MacOS Developer Environment Setup..."
echo "This will take 15-30 minutes depending on your internet connection"
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

# Step 2: Install brew packages from brewfile.txt
log_step "Step 2/7: Installing brew packages..."

BREW_FILE="$SCRIPT_DIR/brewfile.txt"
if [[ -f "$BREW_FILE" ]]; then
    local cask_step_logged=false
    while IFS= read -r package <&3; do
        # Skip empty lines and comments
        [[ -z "$package" || "$package" =~ ^#.*$ ]] && continue

        # Emit GUI step marker on first cask so the Electron app can track progress
        if [[ "$package" == --cask* && "$cask_step_logged" == false ]]; then
            echo ""
            log_step "Step 3/7: Installing GUI applications..."
            cask_step_logged=true
        fi

        log_info "Installing: $package"
        brew install $package || log_warn "Failed to install: $package"
    done 3< "$BREW_FILE"
else
    log_error "brewfile.txt not found at $BREW_FILE"
    exit 1
fi

log_info "Brew packages installation complete"
echo ""

# Step 3: Install gcloud components
log_step "Step 3/7: Installing gcloud components..."
if command -v gcloud &> /dev/null; then
    log_info "Installing gke-gcloud-auth-plugin..."
    gcloud components install gke-gcloud-auth-plugin --quiet 2>&1 || log_warn "Failed to install gke-gcloud-auth-plugin"
fi
echo ""

# Step 4: Install Oh My Zsh
log_step "Step 4/7: Setting up Oh My Zsh..."
if [[ ! -d "$HOME/.oh-my-zsh" ]]; then
    log_info "Installing Oh My Zsh..."
    RUNZSH=no KEEP_ZSHRC=yes sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" 2>&1
else
    log_info "Oh My Zsh already installed"
fi

# Install zsh plugins
log_info "Installing zsh plugins..."
ZSH_CUSTOM="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}"

if [[ ! -d "$ZSH_CUSTOM/plugins/zsh-syntax-highlighting" ]]; then
    git clone https://github.com/zsh-users/zsh-syntax-highlighting.git "$ZSH_CUSTOM/plugins/zsh-syntax-highlighting" 2>&1
else
    log_info "zsh-syntax-highlighting already installed"
fi

if [[ ! -d "$ZSH_CUSTOM/plugins/zsh-autosuggestions" ]]; then
    git clone https://github.com/zsh-users/zsh-autosuggestions "$ZSH_CUSTOM/plugins/zsh-autosuggestions" 2>&1
else
    log_info "zsh-autosuggestions already installed"
fi
echo ""

# Step 5: Setup dotfiles (symlinks)
log_step "Step 5/7: Setting up dotfiles..."
if [[ -d "$SCRIPT_DIR/dotfiles" ]]; then
    for file in "$SCRIPT_DIR/dotfiles"/.??*; do
        [[ "$(basename "$file")" == ".git" ]] && continue
        [[ "$(basename "$file")" == ".DS_Store" ]] && continue
        
        filename=$(basename "$file")
        target="$HOME/$filename"
        
        if [[ -f "$target" && ! -L "$target" ]]; then
            log_warn "Backing up existing $filename to ${filename}.backup"
            mv "$target" "${target}.backup"
        fi
        
        log_info "Symlinking $filename"
        ln -sf "$file" "$target"
    done
else
    log_warn "dotfiles directory not found, skipping..."
fi
echo ""

# Step 6: Install VS Code extensions
log_step "Step 6/7: Installing VS Code extensions..."

if ! command -v code &> /dev/null; then
    export PATH="$PATH:/Applications/Visual Studio Code.app/Contents/Resources/app/bin"
fi

VSCODE_FILE="$SCRIPT_DIR/vscode-extensions.txt"
if command -v code &> /dev/null; then
    if [[ -f "$VSCODE_FILE" ]]; then
        while IFS= read -r extension; do
            [[ -z "$extension" || "$extension" =~ ^#.*$ ]] && continue
            
            log_info "Installing extension: $extension"
            code --install-extension "$extension" --force
        done < "$VSCODE_FILE"
    else
        log_error "vscode-extensions.txt not found at $VSCODE_FILE"
    fi
else
    log_error "VS Code CLI not found. Please ensure VS Code is installed."
    log_error "You may need to open VS Code and run 'Shell Command: Install code command in PATH'"
fi
echo ""

# Step 7: Additional setup
log_step "Step 7/7: Additional setup..."

# Check and install Rosetta 2 if on Apple Silicon
if [[ $(uname -m) == 'arm64' ]]; then
    log_info "Checking for Rosetta 2..."
    if ! /usr/bin/pgrep -q oahd; then
        log_info "Installing Rosetta 2 (required for SnowSQL on Apple Silicon)..."
        softwareupdate --install-rosetta --agree-to-license
    else
        log_info "Rosetta 2 already installed"
    fi
fi

# Install SnowSQL
log_info "Installing SnowSQL..."
if [[ ! -f /Applications/SnowSQL.app/Contents/MacOS/snowsql ]]; then
    log_info "Downloading SnowSQL installer..."
    curl -O https://sfc-repo.snowflakecomputing.com/snowsql/bootstrap/1.2/darwin_x86_64/snowsql-1.2.28-darwin_x86_64.pkg 2>&1
    log_info "Installing SnowSQL (may require password)..."
    sudo installer -pkg snowsql-1.2.28-darwin_x86_64.pkg -target / 2>&1
    rm snowsql-1.2.28-darwin_x86_64.pkg
else
    log_info "SnowSQL already installed"
fi
echo ""

echo "=========================================="
echo "Setup Complete! 🎉"
echo "=========================================="
echo ""
echo "Next steps:"
echo "1. Restart your terminal or run: source ~/.zshrc"
echo "2. Configure your Git credentials if not already set:"
echo "   git config --global user.name 'Your Name'"
echo "   git config --global user.email 'your.email@example.com'"
echo "3. Sign in to services:"
echo "   - Docker Desktop (open the app)"
echo "   - gcloud: gcloud auth login"
echo "   - GitHub: gh auth login"
echo "   - Tailscale: sudo tailscale up"
echo "4. Add your SSH keys to ~/.ssh/ (not included in this repo for security)"
echo "5. Configure SnowSQL: snowsql -a <account> -u <username>"
echo ""
echo "Note: Some applications may require a restart to work properly"
echo ""