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
echo "[STEP] Step 1/7: Checking Homebrew installation..."
if ! command -v brew &> /dev/null; then
    echo "[INFO] Installing Homebrew..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    
    # Add Homebrew to PATH for Apple Silicon Macs
    if [[ $(uname -m) == 'arm64' ]]; then
        echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> ~/.zprofile
        eval "$(/opt/homebrew/bin/brew shellenv)"
    fi
else
    echo "[INFO] Homebrew already installed"
    brew update
fi
echo ""

# Step 2: Install CLI packages
echo "[STEP] Step 2/7: Installing CLI packages..."

# Core utilities
echo "[INFO] Installing core utilities..."
brew install coreutils binutils diffutils gnutls jq bazelisk 2>&1

# Development tools
echo "[INFO] Installing development tools..."
brew install gcc parallel make gnu-sed graphviz python-yq 2>&1

# Programming languages and tools
echo "[INFO] Installing programming languages and cloud tools..."
brew install git go docker docker-compose kubectl openblas node helm terraform hcl2json gh 2>&1

# Python
echo "[INFO] Installing Python..."
brew install python@3.11 2>&1

echo "[INFO] CLI packages installation complete"
echo ""

# Step 3: Install GUI applications
echo "[STEP] Step 3/7: Installing GUI applications..."

echo "[INFO] Installing Visual Studio Code..."
brew install --cask visual-studio-code 2>&1

echo "[INFO] Installing iTerm2..."
brew install --cask iterm2 2>&1

echo "[INFO] Installing Docker Desktop..."
brew install --cask docker 2>&1

echo "[INFO] Installing Tailscale..."
brew install --cask tailscale 2>&1

echo "[INFO] Installing Google Cloud SDK..."
brew install --cask google-cloud-sdk 2>&1

echo "[INFO] GUI applications installation complete"
echo ""

# Step 4: Install gcloud components
echo "[STEP] Step 4/7: Installing gcloud components..."
if command -v gcloud &> /dev/null; then
    echo "[INFO] Installing gke-gcloud-auth-plugin..."
    gcloud components install gke-gcloud-auth-plugin --quiet 2>&1 || echo "[WARN] Failed to install gke-gcloud-auth-plugin"
fi
echo ""

# Step 5: Install Oh My Zsh
echo "[STEP] Step 5/7: Setting up Oh My Zsh..."
if [[ ! -d "$HOME/.oh-my-zsh" ]]; then
    echo "[INFO] Installing Oh My Zsh..."
    RUNZSH=no KEEP_ZSHRC=yes sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" 2>&1
else
    echo "[INFO] Oh My Zsh already installed"
fi

# Install zsh plugins
echo "[INFO] Installing zsh plugins..."
ZSH_CUSTOM="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}"

# zsh-syntax-highlighting
if [[ ! -d "$ZSH_CUSTOM/plugins/zsh-syntax-highlighting" ]]; then
    git clone https://github.com/zsh-users/zsh-syntax-highlighting.git "$ZSH_CUSTOM/plugins/zsh-syntax-highlighting" 2>&1
else
    echo "[INFO] zsh-syntax-highlighting already installed"
fi

# zsh-autosuggestions
if [[ ! -d "$ZSH_CUSTOM/plugins/zsh-autosuggestions" ]]; then
    git clone https://github.com/zsh-users/zsh-autosuggestions "$ZSH_CUSTOM/plugins/zsh-autosuggestions" 2>&1
else
    echo "[INFO] zsh-autosuggestions already installed"
fi
echo ""

# Step 6: Setup dotfiles (symlinks)
echo "[STEP] Step 6/7: Setting up dotfiles..."
if [[ -d "$SCRIPT_DIR/dotfiles" ]]; then
    for file in "$SCRIPT_DIR/dotfiles"/.??*; do
        [[ "$(basename "$file")" == ".git" ]] && continue
        [[ "$(basename "$file")" == ".DS_Store" ]] && continue
        
        filename=$(basename "$file")
        target="$HOME/$filename"
        
        # Backup existing file if it exists and is not a symlink
        if [[ -f "$target" && ! -L "$target" ]]; then
            echo "[WARN] Backing up existing $filename to ${filename}.backup"
            mv "$target" "${target}.backup"
        fi
        
        # Create symlink
        echo "[INFO] Symlinking $filename"
        ln -sf "$file" "$target"
    done
else
    echo "[WARN] dotfiles directory not found, skipping..."
fi
echo ""

# Step 7: Install VS Code extensions
echo "Step 7: Installing VS Code extensions..."

# Add VS Code to PATH if it's not already there
if ! command -v code &> /dev/null; then
    export PATH="$PATH:/Applications/Visual Studio Code.app/Contents/Resources/app/bin"
fi

# Verify code is now available
if command -v code &> /dev/null; then
    while IFS= read -r extension; do
        echo "Installing extension: $extension"
        code --install-extension "$extension" --force
    done < vscode-extensions.txt
else
    echo "ERROR: VS Code CLI not found. Please ensure VS Code is installed."
    echo "You may need to open VS Code and run 'Shell Command: Install code command in PATH'"
fi
echo ""

# Check and install Rosetta 2 if on Apple Silicon
if [[ $(uname -m) == 'arm64' ]]; then
    echo "Checking for Rosetta 2..."
    if ! /usr/bin/pgrep -q oahd; then
        echo "Installing Rosetta 2 (required for SnowSQL on Apple Silicon)..."
        softwareupdate --install-rosetta --agree-to-license
    else
        echo "Rosetta 2 already installed."
    fi
fi

# Install SnowSQL manually (not available via Homebrew)
echo "[INFO] Installing SnowSQL..."
if [[ ! -f /Applications/SnowSQL.app/Contents/MacOS/snowsql ]]; then
    echo "[INFO] Downloading SnowSQL installer..."
    curl -O https://sfc-repo.snowflakecomputing.com/snowsql/bootstrap/1.2/darwin_x86_64/snowsql-1.2.28-darwin_x86_64.pkg 2>&1
    echo "[INFO] Installing SnowSQL (may require password)..."
    sudo installer -pkg snowsql-1.2.28-darwin_x86_64.pkg -target / 2>&1
    rm snowsql-1.2.28-darwin_x86_64.pkg
else
    echo "[INFO] SnowSQL already installed"
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