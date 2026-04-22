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

# Create required directories
echo "📁 Creating directory structure..."
sudo mkdir -p /opt/gists
sudo chown $USER:staff /opt/gists
mkdir -p ~/dotfiles/config/starship

# Create plugins directory and install plugins
echo "🔧 Installing zsh plugins..."
mkdir -p ~/.local/share/zsh/plugins
# git clone https://github.com/zsh-users/zsh-autosuggestions ~/.local/share/zsh/plugins/zsh-autosuggestions
# git clone https://github.com/zdharma-continuum/fast-syntax-highlighting ~/.local/share/zsh/plugins/fast-syntax-highlighting
# git clone https://github.com/zsh-users/zsh-history-substring-search ~/.local/share/zsh/plugins/zsh-history-substring-search

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

# Shell init: symlink repo → home (INST-* / Phase 6). Idempotent; backs up replaced files.
echo "📝 Linking shell configuration (symlinks)..."
REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BACKUP_ROOT="${HOME}/.dotfiles-backup"
TS="$(date +%Y%m%d-%H%M%S)"
BACKUP_DIR="${BACKUP_ROOT}/${TS}"

backup_if_regular() {
  local target="$1"
  [[ -e "$target" || -L "$target" ]] || return 0
  # Replace only real files / wrong symlinks; skip if already points into this repo
  if [[ -L "$target" ]]; then
    local cur
    cur="$(readlink "$target")"
    [[ "$cur" == "${REPO_ROOT}"/* ]] && return 0
  fi
  mkdir -p "$BACKUP_DIR"
  echo "   Backup: $target → $BACKUP_DIR/"
  mv "$target" "$BACKUP_DIR/"
}

symlink_init() {
  local name="$1"   # basename under REPO_ROOT
  local dest="$2"   # absolute path in HOME
  mkdir -p "$(dirname "$dest")"
  backup_if_regular "$dest"
  ln -sf "${REPO_ROOT}/${name}" "$dest"
}

mkdir -p "${HOME}/dotfiles/config/starship"
# Canonical files live in this repo (typically ~/dotfiles); home entries point here.
symlink_init ".zshrc" "${HOME}/.zshrc"
symlink_init ".zshenv" "${HOME}/.zshenv"
symlink_init ".zprofile" "${HOME}/.zprofile"
cp "${REPO_ROOT}/config/starship/starship.toml" "${HOME}/dotfiles/config/starship/"
cp "${REPO_ROOT}/.zsh.functions" "${HOME}/dotfiles/"
cp "${REPO_ROOT}/.zsh.aliases" "${HOME}/dotfiles/"

# Create empty secrets file if it doesn't exist
touch ~/secrets.sh

# Configure fzf
echo "🔍 Configuring fzf..."
$(brew --prefix)/opt/fzf/install --all

# Create zsh history file
mkdir -p ~/.zsh
touch ~/.zsh/history

# Install and configure zsh
echo "🐚 Setting up zsh..."
if ! command -v zsh >/dev/null 2>&1; then
    echo "Installing zsh..."
    brew install zsh
fi

# Add Homebrew's zsh to allowed shells if not already present
BREW_ZSH="$(brew --prefix)/bin/zsh"
if ! grep -q "$BREW_ZSH" /etc/shells; then
    echo "Adding Homebrew's zsh to allowed shells..."
    echo "$BREW_ZSH" | sudo tee -a /etc/shells
fi

# Set zsh as default shell if it isn't already
if [[ $SHELL != *"zsh"* ]]; then
    echo "🐚 Setting Homebrew's zsh as default shell..."
    chsh -s "$BREW_ZSH"
fi

echo "✨ Installation complete!"
echo "Please log out and log back in to ensure all changes take effect."
echo "If you don't want to log out, you can start a new zsh session by running:"
echo "exec $BREW_ZSH"

# Print maintenance instructions
echo "
🔧 Maintenance Commands:
- Update Homebrew packages: brew update && brew upgrade
- Update plugins: cd ~/.local/share/zsh/plugins/* && git pull
- Update tldr pages: tldr --update
- Update Starship: brew upgrade starship
"
