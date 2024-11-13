#!/bin/bash

set -e  # Exit on error

echo "🚀 Starting dotfiles installation..."

# Check for Xcode Command Line Tools
if ! command -v git >/dev/null 2>&1; then
    echo "📦 Installing Xcode Command Line Tools..."
    xcode-select --install
    echo "⏳ Waiting for Xcode Command Line Tools installation to complete..."
    until command -v git >/dev/null 2>&1; do sleep 5; done
fi

# Install Homebrew if not present
if ! command -v brew >/dev/null 2>&1; then
    echo "🍺 Installing Homebrew..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    
    # Add Homebrew to PATH for the installation process
    eval "$(/opt/homebrew/bin/brew shellenv)" 2>/dev/null || eval "$(/usr/local/bin/brew shellenv)"
fi

# Install essential packages
echo "📦 Installing essential packages..."
brew install \
    eza \
    ripgrep \
    fzf \
    tmux \
    grc \
    blueutil \
    gsed \
    rlwrap \
    fd \
    bat \
    delta \
    tldr \
    the_silver_searcher \
    highlight \
    zoxide \
    nmap \
    ffmpeg \
    imagemagick \
    openssl \
    python \
    ipython \
    starship

# Install recommended applications
echo "📱 Installing recommended applications..."
brew install --cask iterm2
brew install --cask anaconda

# Create required directories
echo "📁 Creating directory structure..."
sudo mkdir -p /opt/gists
sudo chown $USER:staff /opt/gists
mkdir -p ~/dotfiles/config/starship

# Install zap plugin manager
echo "🔌 Installing zap plugin manager..."
mkdir -p "$HOME/.local/share/zap"
git clone https://github.com/zap-zsh/zap.git "$HOME/.local/share/zap"

# Create plugins directory and install plugins
echo "🔧 Installing zsh plugins..."
mkdir -p ~/.local/share/zsh/plugins
git clone https://github.com/zsh-users/zsh-autosuggestions ~/.local/share/zsh/plugins/zsh-autosuggestions
git clone https://github.com/zdharma-continuum/fast-syntax-highlighting ~/.local/share/zsh/plugins/fast-syntax-highlighting
git clone https://github.com/zsh-users/zsh-history-substring-search ~/.local/share/zsh/plugins/zsh-history-substring-search

# Install development tools
echo "🛠️ Installing development tools..."

# Install NVM
echo "📦 Installing NVM..."
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.0/install.sh | bash

# Install Bun
echo "🥟 Installing Bun..."
curl -fsSL https://bun.sh/install | bash

# Install Rust
echo "🦀 Installing Rust..."
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y

# Install Python packages
echo "🐍 Installing Python packages..."
pip3 install virtualenv ipython

# Copy configuration files
echo "📝 Copying configuration files..."
cp .zshrc ~/.zshrc
cp completions.zsh ~/dotfiles/
cp config/starship/starship.toml ~/dotfiles/config/starship/
cp .zsh.functions ~/dotfiles/
cp .zsh.aliases ~/dotfiles/

# Create empty secrets file if it doesn't exist
touch ~/secrets.sh

# Configure fzf
echo "🔍 Configuring fzf..."
$(brew --prefix)/opt/fzf/install --all

# Create zsh history file
mkdir -p ~/.zsh
touch ~/.zsh/history

# Set zsh as default shell if it isn't already
if [[ $SHELL != *"zsh"* ]]; then
    echo "🐚 Setting zsh as default shell..."
    command -v zsh | sudo tee -a /etc/shells
    chsh -s $(command -v zsh)
fi

echo "✨ Installation complete! Please restart your terminal or run:"
echo "source ~/.zshrc"

# Print maintenance instructions
echo "
🔧 Maintenance Commands:
- Update Homebrew packages: brew update && brew upgrade
- Update plugins: cd ~/.local/share/zsh/plugins/* && git pull
- Update tldr pages: tldr --update
- Update Starship: brew upgrade starship
"