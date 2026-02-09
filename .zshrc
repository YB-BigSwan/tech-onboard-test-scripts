# Path to your oh-my-zsh installation.
export ZSH="$HOME/.oh-my-zsh"

# Set name of the theme to load
ZSH_THEME="robbyrussell"

# Plugins
plugins=(
    git
    docker
    kubectl
    terraform
    golang
    python
    zsh-syntax-highlighting
    zsh-autosuggestions
)

source $ZSH/oh-my-zsh.sh

# User configuration

# Homebrew (Apple Silicon)
if [[ $(uname -m) == 'arm64' ]]; then
    eval "$(/opt/homebrew/bin/brew shellenv)"
fi

# Python
export PATH="/opt/homebrew/opt/python@3.11/bin:$PATH"

# Go
export GOPATH="$HOME/go"
export PATH="$PATH:$GOPATH/bin"

# GNU tools (prefer over macOS defaults)
export PATH="/opt/homebrew/opt/coreutils/libexec/gnubin:$PATH"
export PATH="/opt/homebrew/opt/gnu-sed/libexec/gnubin:$PATH"
export PATH="/opt/homebrew/opt/make/libexec/gnubin:$PATH"

# SnowSQL
export PATH="/Applications/SnowSQL.app/Contents/MacOS:$PATH"

# Google Cloud SDK
if [ -f '/opt/homebrew/Caskroom/google-cloud-sdk/latest/google-cloud-sdk/path.zsh.inc' ]; then
    source '/opt/homebrew/Caskroom/google-cloud-sdk/latest/google-cloud-sdk/path.zsh.inc'
fi
if [ -f '/opt/homebrew/Caskroom/google-cloud-sdk/latest/google-cloud-sdk/completion.zsh.inc' ]; then
    source '/opt/homebrew/Caskroom/google-cloud-sdk/latest/google-cloud-sdk/completion.zsh.inc'
fi

# Docker
export DOCKER_BUILDKIT=1

# Aliases
alias k="kubectl"
alias tf="terraform"
alias dc="docker-compose"
alias gs="git status"
alias ga="git add"
alias gc="git commit"
alias gp="git push"
alias gl="git log --oneline --graph --decorate"

# History settings
HISTSIZE=10000
SAVEHIST=10000
setopt SHARE_HISTORY

# Case-insensitive completion
zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}'