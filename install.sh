#!/usr/bin/env bash
# Dotfiles bootstrap + deploy. Use `./install.sh --link-only` for symlink-only (no brew/nvm/rust).
set -e

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOTFILES_TARGET="${DOTFILES:-$HOME/dotfiles}"
export DOTFILES="$DOTFILES_TARGET"
BACKUP_ROOT="${HOME}/.dotfiles-backup"
TS="$(date +%Y%m%d-%H%M%S)"
BACKUP_DIR="${BACKUP_ROOT}/${TS}"

backup_if_needed() {
  local target="$1"
  local src="$2"
  [[ -e "$target" || -L "$target" ]] || return 0
  if [[ -L "$target" ]]; then
    local cur
    cur="$(readlink "$target")"
    [[ "$cur" == "$src" ]] && return 0
  fi
  mkdir -p "$BACKUP_DIR"
  echo "   Backup: $target → $BACKUP_DIR/"
  mv "$target" "$BACKUP_DIR/"
}

symlink_init() {
  local rel="$1"
  local dest="$2"
  local src="${REPO_ROOT}/${rel}"
  if [[ ! -e "$src" && ! -L "$src" ]]; then
    echo "install.sh: missing source file: $src" >&2
    return 1
  fi
  mkdir -p "$(dirname "$dest")"
  backup_if_needed "$dest" "$src"
  ln -sf "$src" "$dest"
}

link_dotfiles() {
  echo "📝 Symlinking shell + portable configs (DOTFILES_TARGET=$DOTFILES_TARGET)…"
  mkdir -p "${DOTFILES_TARGET}/config/starship"
  symlink_init ".zshrc" "${HOME}/.zshrc"
  symlink_init ".zshenv" "${HOME}/.zshenv"
  symlink_init ".zprofile" "${HOME}/.zprofile"
  symlink_init ".zsh.aliases" "${DOTFILES_TARGET}/.zsh.aliases"
  symlink_init ".zsh.functions" "${DOTFILES_TARGET}/.zsh.functions"
  symlink_init "config/starship/starship.toml" "${DOTFILES_TARGET}/config/starship/starship.toml"
  if [[ -f "${REPO_ROOT}/.tmux.conf" ]]; then
    symlink_init ".tmux.conf" "${HOME}/.tmux.conf"
  fi
}

if [[ "${1:-}" == "--link-only" ]]; then
  link_dotfiles
  echo "✨ Link-only complete (no packages installed)."
  exit 0
fi

echo "🚀 Starting dotfiles installation (full bootstrap)…"

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

echo "📱 Installing recommended applications..."

echo "📁 Creating directory structure..."
sudo mkdir -p /opt/gists
sudo chown "$USER:staff" /opt/gists

echo "🔧 Preparing zsh plugin paths (Zap lives under ~/.local/share/zap — install Zap separately if needed)…"
mkdir -p ~/.local/share/zsh/plugins

echo "🛠️ Installing development tools (NVM / Bun / Rust)…"
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.0/install.sh | bash
curl -fsSL https://bun.sh/install | bash
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y

link_dotfiles

touch ~/secrets.sh

echo "🔍 Configuring fzf..."
"$(brew --prefix)/opt/fzf/install" --all

mkdir -p ~/.zsh
touch ~/.zsh/history

echo "🐚 Setting up zsh..."
if ! command -v zsh >/dev/null 2>&1; then
    brew install zsh
fi

BREW_ZSH="$(brew --prefix)/bin/zsh"
if ! grep -q "$BREW_ZSH" /etc/shells; then
    echo "Adding Homebrew's zsh to allowed shells..."
    echo "$BREW_ZSH" | sudo tee -a /etc/shells
fi

if [[ $SHELL != *"zsh"* ]]; then
    echo "🐚 Setting Homebrew's zsh as default shell..."
    chsh -s "$BREW_ZSH"
fi

echo "✨ Installation complete!"
echo "Re-run safely: ./install.sh --link-only"
echo "exec $BREW_ZSH"

echo "
🔧 Maintenance:
- brew update && brew upgrade
- tldr --update
"
