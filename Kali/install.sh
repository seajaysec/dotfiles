#!/usr/bin/env bash
set -euo pipefail

# Kali/Debian bootstrap for your dotfiles (zsh + tmux + starship + pyenv deps + fonts)
# Run: bash ~/dotfiles/Kali/install.sh

DOTFILES_DIR="${DOTFILES_DIR:-$HOME/dotfiles}"
KALI_DIR="$DOTFILES_DIR/Kali"

require_cmd() {
  command -v "$1" >/dev/null 2>&1 || { echo "Missing required command: $1"; exit 1; }
}

echo "==> Detecting apt..."
require_cmd apt-get
require_cmd curl
require_cmd git

echo "==> Updating apt metadata..."
sudo apt-get update -y

echo "==> Installing base packages..."
PKGS=(
  zsh git curl wget ca-certificates unzip fontconfig
  build-essential pkg-config
  ripgrep silversearcher-ag fzf
  bat fd-find
  zoxide thefuck direnv
  tmux jq dnsutils nmap netcat-openbsd grc rlwrap
  xclip xsel
  python3 python3-pip python3-venv
  pandoc ffmpeg imagemagick
  # pyenv build deps
  libssl-dev zlib1g-dev libbz2-dev libreadline-dev libsqlite3-dev
  libncursesw5-dev libffi-dev liblzma-dev tk-dev xz-utils
)

if apt-cache show eza >/dev/null 2>&1; then
  PKGS+=(eza)
elif apt-cache show exa >/dev/null 2>&1; then
  PKGS+=(exa)
fi

sudo apt-get install -y "${PKGS[@]}"

# Ensure bat is available as 'bat' if only 'batcat' exists
if ! command -v bat >/dev/null 2>&1 && command -v batcat >/dev/null 2>&1; then
  echo "==> Creating /usr/local/bin/bat symlink to batcat"
  sudo ln -sf "$(command -v batcat)" /usr/local/bin/bat
fi

echo "==> Installing starship..."
if ! command -v starship >/dev/null 2>&1; then
  curl -fsSL https://starship.rs/install.sh | bash -s -- -y
fi

echo "==> Installing bun (optional)..."
if [ ! -d "$HOME/.bun" ]; then
  curl -fsSL https://bun.sh/install | bash -s -- -y || true
fi

echo "==> Installing pyenv..."
if [ ! -d "$HOME/.pyenv" ]; then
  git clone https://github.com/pyenv/pyenv.git "$HOME/.pyenv"
fi

echo "==> Setting up tmux: oh-my-tmux + TPM + logs dir..."
if [ ! -d "$HOME/.tmux" ]; then
  git clone https://github.com/gpakosz/.tmux.git "$HOME/.tmux"
  ln -sf "$HOME/.tmux/.tmux.conf" "$HOME/.tmux.conf"
fi
ln -sf "$KALI_DIR/.tmux.conf.local" "$HOME/.tmux.conf.local"
mkdir -p "$HOME/tmuxlogs"

if [ ! -d "$HOME/.tmux/plugins/tpm" ]; then
  git clone https://github.com/tmux-plugins/tpm "$HOME/.tmux/plugins/tpm"
fi

echo "==> Installing tmux plugins..."
"$HOME/.tmux/plugins/tpm/bin/install_plugins" || true

echo "==> Installing Hack Nerd Font..."
NF_DIR="$HOME/.local/share/fonts/NerdFonts"
mkdir -p "$NF_DIR"
HACK_ZIP="$NF_DIR/Hack.zip"
if [ ! -f "$HACK_ZIP" ]; then
  curl -fsSL -o "$HACK_ZIP" https://github.com/ryanoasis/nerd-fonts/releases/latest/download/Hack.zip || true
fi
if [ -f "$HACK_ZIP" ]; then
  unzip -oq "$HACK_ZIP" -d "$NF_DIR"
  fc-cache -f -v >/dev/null 2>&1 || true
fi

echo "==> Linking zsh dotfiles (Kali)..."
ln -sf "$KALI_DIR/.zshrc" "$HOME/.zshrc"
ln -sf "$KALI_DIR/.zsh.aliases" "$HOME/.zsh.aliases"
ln -sf "$KALI_DIR/.zsh.functions" "$HOME/.zsh.functions"
# p10k fallback uses your existing file
if [ -f "$DOTFILES_DIR/.p10k.zsh" ]; then
  ln -sf "$DOTFILES_DIR/.p10k.zsh" "$HOME/.p10k.zsh"
fi

echo "==> Making zsh the default shell..."
if [ "$(basename "${SHELL:-}")" != "zsh" ]; then
  ZSH_BIN="$(command -v zsh)"
  if ! grep -q "$ZSH_BIN" /etc/shells; then
    echo "Adding $ZSH_BIN to /etc/shells (sudo required)"
    echo "$ZSH_BIN" | sudo tee -a /etc/shells >/dev/null
  fi
  chsh -s "$ZSH_BIN" || true
fi

echo
echo "All set!"
echo "- Open a new terminal to start zsh. tmux will auto-start and (with continuum) will auto-restore."
echo "- Starship config: $DOTFILES_DIR/config/starship/starship.toml"
echo "- If fonts don't render correctly, ensure 'Hack Nerd Font' is selected in your terminal profile."
echo

