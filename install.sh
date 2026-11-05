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
  # Repo at DOTFILES_TARGET: dest can equal src (same path) — skip self-symlink.
  if [[ "$src" -ef "$dest" ]]; then
    return 0
  fi
  mkdir -p "$(dirname "$dest")"
  backup_if_needed "$dest" "$src"
  ln -sf "$src" "$dest"
}

# iTerm: one static "Default" profile running zsh (apply-iterm-defaults.sh).
# Clears dynamic profiles left over from older setups (APS, tmux -CC).
setup_iterm_dynamic_profiles() {
  local dyn_dir="${HOME}/Library/Application Support/iTerm2/DynamicProfiles"
  local apply="${REPO_ROOT}/config/iterm2/apply-iterm-defaults.sh"
  if [[ -d "$dyn_dir" ]]; then
    rm -f "${dyn_dir}/tmux.json" "${dyn_dir}/plain.json" "${dyn_dir}/aps-projects.json"
  fi
  # Old rendered APS file: machine paths, no longer gitignored — never commit it.
  rm -rf "${REPO_ROOT}/config/iterm2/DynamicProfiles"

  [[ -d /Applications/iTerm.app ]] || return 0
  if defaults read com.googlecode.iterm2 "New Bookmarks" 2>/dev/null | grep -q '"Custom Command" = "Custom Shell"'; then
    return 0   # already one zsh profile
  fi
  if ! pgrep -xq iTerm2; then
    "$apply"
  elif ! pgrep -fq 'dotfiles-iterm-apply-on-quit'; then
    # iTerm rewrites its prefs on quit, so wait for ⌘Q, then apply and relaunch.
    # Session Restoration keeps running shells alive across the quit.
    nohup /bin/bash -c '
      : dotfiles-iterm-apply-on-quit
      while pgrep -xq iTerm2; do sleep 1; done
      for _ in 1 2 3 4 5 6 7 8 9 10; do "$0" && break; sleep 2; done
      open -a iTerm' "$apply" >"${HOME}/Library/Logs/dotfiles-iterm-apply.log" 2>&1 </dev/null &
    disown
    echo "   iTerm: quit iTerm (⌘Q) once — profile switches to zsh and iTerm relaunches."
  fi
}

# Daily iTerm log retention (compress >7d, delete >45d). Idempotent.
setup_iterm_log_retention() {
  local label="com.dotfiles.iterm-log-retention"
  local plist="$HOME/Library/LaunchAgents/${label}.plist"
  mkdir -p "$HOME/Library/LaunchAgents" "$HOME/Library/Logs/iTerm2"
  cat > "$plist" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key><string>${label}</string>
    <key>ProgramArguments</key>
    <array><string>/bin/sh</string><string>${HOME}/.local/bin/iterm-log-retention</string></array>
    <key>StartCalendarInterval</key>
    <dict><key>Hour</key><integer>12</integer><key>Minute</key><integer>30</integer></dict>
    <key>RunAtLoad</key><true/>
    <key>StandardErrorPath</key><string>${HOME}/Library/Logs/iterm-log-retention.log</string>
</dict>
</plist>
PLIST
  launchctl bootout "gui/$(id -u)/${label}" >/dev/null 2>&1 || true
  launchctl bootstrap "gui/$(id -u)" "$plist" >/dev/null 2>&1 || true
}

# Python = uv. uv-managed 3.12 is the default python3 (~/.local/bin, first on
# PATH); projects get their own ./.venv. pyenv / pipx / ~/.virtualenvs retired.
setup_python_uv() {
  command -v uv >/dev/null 2>&1 || return 0
  UV_PYTHON_PREFERENCE=only-managed uv python install 3.12 --default >/dev/null 2>&1 \
    && echo "   python: $(~/.local/bin/python3 --version 2>&1) via uv (default python3)"
  if [[ -d "$HOME/.virtualenvs" || -d "$HOME/.pyenv" || -d "$HOME/.local/pipx" ]] \
     || find "$HOME" -maxdepth 6 -name .venv -type f -not -path "$HOME/Library/*" 2>/dev/null | grep -q .; then
    echo ""
    echo "   ⚠️  python: old pyenv / pipx / ~/.virtualenvs setup found on this machine."
    echo "      Move it to uv and archive the rest (asks before each step): py-legacy-sweep"
    echo ""
  fi
}

# Login shell = stock /bin/bash so AI tools (Claude Code, Codex, Cursor) get a
# vanilla environment; zsh runs inside iTerm. Read the real account setting:
# $SHELL is forced to /bin/bash inside zsh, so it can't be trusted.
ensure_login_shell() {
  local cur
  cur="$(dscl . -read "/Users/$USER" UserShell | awk '{print $2}')"
  if [[ "$cur" != /bin/bash ]]; then
    echo "🐚 Setting /bin/bash as login shell (was $cur)..."
    chsh -s /bin/bash
  fi
}

# Go: Homebrew's is the only one. A leftover go.dev .pkg in /usr/local/go
# shadows it on minimal PATHs (GUI apps, launchd, sudo, agents), so `go install`
# silently builds with a different version.
remove_stale_go() {
  if [[ -d /usr/local/go ]] && command -v brew >/dev/null 2>&1 && [[ -x "$(brew --prefix)/bin/go" ]]; then
    echo "🐹 Removing stale /usr/local/go ($(/usr/local/go/bin/go version 2>/dev/null)) — Homebrew go is canonical..."
    sudo rm -rf /usr/local/go /usr/local/bin/go /usr/local/bin/gofmt
  fi
}

link_dotfiles() {
  echo "📝 Symlinking shell + portable configs (DOTFILES_TARGET=$DOTFILES_TARGET)…"
  mkdir -p "${DOTFILES_TARGET}/config/starship"
  symlink_init ".zshrc" "${HOME}/.zshrc"
  symlink_init ".zshenv" "${HOME}/.zshenv"
  symlink_init ".zprofile" "${HOME}/.zprofile"
  symlink_init ".profile" "${HOME}/.profile"
  symlink_init ".bash_profile" "${HOME}/.bash_profile"
  symlink_init ".bashrc" "${HOME}/.bashrc"
  symlink_init "bin/unwrap-clipboard" "${HOME}/.local/bin/unwrap-clipboard"
  symlink_init "bin/iterm-log-retention" "${HOME}/.local/bin/iterm-log-retention"
  symlink_init "bin/venv-migrate" "${HOME}/.local/bin/venv-migrate"
  symlink_init "bin/py-legacy-sweep" "${HOME}/.local/bin/py-legacy-sweep"
  symlink_init ".zsh.aliases" "${DOTFILES_TARGET}/.zsh.aliases"
  symlink_init ".zsh.functions" "${DOTFILES_TARGET}/.zsh.functions"
  symlink_init "config/starship/starship.toml" "${DOTFILES_TARGET}/config/starship/starship.toml"
  # Static zsh completions land in ~/.zfunc (already on fpath in .zshrc before compinit).
  # Regenerate after `brew upgrade quien`: quien completion zsh > config/zsh/completions/_quien
  symlink_init "config/zsh/completions/_quien" "${HOME}/.zfunc/_quien"
  if [[ -f "${REPO_ROOT}/.tmux.conf" ]]; then
    symlink_init ".tmux.conf" "${HOME}/.tmux.conf"
  fi
  if [[ -f "${REPO_ROOT}/.tmux.conf.local" ]]; then
    symlink_init ".tmux.conf.local" "${HOME}/.tmux.conf.local"
  fi
  if [[ -f "${REPO_ROOT}/.gitignore_global" ]]; then
    symlink_init ".gitignore_global" "${HOME}/.gitignore_global"
  fi
  # Agent-chat archive viewer: self-contained, server-less HTML browser for
  # specstory history (populated by the `ssync` shell function). These are
  # COPIED (not symlinked) into the hidden archive dir on purpose: browsers
  # canonicalize a symlinked file:// document to its real path, which would make
  # the viewer's relative data.js/marked/purify resolve against the repo dir
  # (where they aren't siblings) and load nothing. Real files keep the archive
  # self-contained and portable. Re-run install.sh after editing the viewer.
  if [[ -d "${REPO_ROOT}/config/agent-chats" ]]; then
    local ac_dest="${HOME}/.secrets/agent-chats"
    mkdir -p "$ac_dest"
    # rm first so `cp` writes a fresh real file instead of following a stale symlink.
    rm -f "${ac_dest}/viewer.html" "${ac_dest}/build-index.py" \
          "${ac_dest}/collect-native.py" \
          "${ac_dest}/marked.min.js" "${ac_dest}/purify.min.js"
    cp "${REPO_ROOT}/config/agent-chats/viewer.html"          "${ac_dest}/viewer.html"
    cp "${REPO_ROOT}/config/agent-chats/build-index.py"       "${ac_dest}/build-index.py"
    cp "${REPO_ROOT}/config/agent-chats/collect-native.py"    "${ac_dest}/collect-native.py"
    cp "${REPO_ROOT}/config/agent-chats/vendor/marked.min.js" "${ac_dest}/marked.min.js"
    cp "${REPO_ROOT}/config/agent-chats/vendor/purify.min.js" "${ac_dest}/purify.min.js"
    echo "   agent-chats: viewer + libs copied → ${ac_dest}"
  fi
  setup_iterm_dynamic_profiles
  # Shared AI-tool layer: rules, python-env skill, uv command guard for Claude
  # Code, Cursor and Codex (CLI + app each). Needs jq (installed by full bootstrap).
  if command -v jq >/dev/null 2>&1; then
    "${REPO_ROOT}/config/ai/install-ai.sh"
  else
    echo "   ai: skipped (install jq, then re-run)" >&2
  fi
  # Neovim config (whole directory).
  if [[ -d "${REPO_ROOT}/config/nvim" ]]; then
    mkdir -p "${HOME}/.config"
    symlink_init "config/nvim" "${HOME}/.config/nvim"
  fi
  # Git: ~/.gitconfig stays machine-local (git lfs / gh / credential helpers
  # write there) and just includes the tracked file, so `git config --global`
  # never edits this repo.
  if [[ -f "${REPO_ROOT}/.gitconfig" ]]; then
    touch "${HOME}/.gitconfig"
    if ! git config --global --get-all include.path 2>/dev/null | grep -qxF "${DOTFILES_TARGET}/.gitconfig"; then
      git config --global --add include.path "${DOTFILES_TARGET}/.gitconfig"
      echo "   git: ~/.gitconfig now includes ${DOTFILES_TARGET}/.gitconfig"
    fi
    git -C "$REPO_ROOT" config --local --unset-all user.email 2>/dev/null || true
  fi
  # Shared VS Code + Cursor User settings (same file; Cursor-only keys are ignored by VS Code).
  # Python interpreter: zsh `code`/`cursor` wrappers set PATH + VIRTUAL_ENV when autoswitch `.venv` exists; no defaultInterpreterPath in JSON.
  if [[ -f "${REPO_ROOT}/config/editor/User/settings.json" ]]; then
    symlink_init "config/editor/User/settings.json" "${HOME}/Library/Application Support/Code/User/settings.json"
    symlink_init "config/editor/User/settings.json" "${HOME}/Library/Application Support/Cursor/User/settings.json"
  fi
}

if [[ "${1:-}" == "--link-only" ]]; then
  link_dotfiles
  remove_stale_go
  setup_python_uv
  setup_iterm_log_retention
  ensure_login_shell
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
    git \
    git-lfs \
    gh \
    glab \
    zsh \
    neovim \
    jq \
    pkgconf \
    uv \
    node \
    go \
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
    git-delta \
    tldr \
    the_silver_searcher \
    highlight \
    zoxide \
    nmap \
    ffmpeg \
    imagemagick \
    openssl \
    python

if [[ ! -d /Applications/iTerm.app ]]; then
  echo "🖥️  Installing iTerm2..."
  brew install --cask iterm2
fi
git lfs install --skip-repo >/dev/null 2>&1 || true

remove_stale_go
setup_iterm_log_retention
setup_python_uv

echo "📁 Creating directory structure..."
if [[ ! -d /opt/gists ]]; then
  sudo mkdir -p /opt/gists
  sudo chown "$USER:staff" /opt/gists
fi

echo "🔌 zsh plugin manager (Zap) + iTerm shell integration…"
mkdir -p ~/.local/share/zsh/plugins
# Clone instead of Zap's installer: the installer rewrites ~/.zshrc (a symlink
# into this repo). Plugins themselves install on first zsh start via `plug`.
if [[ ! -f "$HOME/.local/share/zap/zap.zsh" ]]; then
  git clone --depth 1 -b release-v1 https://github.com/zap-zsh/zap.git "$HOME/.local/share/zap"
fi
# Status bar user vars + cwd tracking depend on this (sourced by .zshrc).
if [[ ! -f "$HOME/.iterm2_shell_integration.zsh" ]]; then
  curl -fsSL https://iterm2.com/shell_integration/zsh -o "$HOME/.iterm2_shell_integration.zsh"
fi

# Each upstream installer below appends a shell-init block to ~/.zshrc.
# That mutates this repo (since ~/.zshrc is a symlink into it). Guard with
# command -v so re-runs of install.sh don't re-pollute committed files.
# Node comes from Homebrew (above); no nvm.
echo "🛠️ Installing development tools (Bun / Rust) — skipping any already installed…"
if ! command -v bun >/dev/null 2>&1 && [[ ! -x "$HOME/.bun/bin/bun" ]]; then
  echo "   → bun"
  curl -fsSL https://bun.sh/install | bash
else
  echo "   → bun already installed (skip)"
fi
if ! command -v rustc >/dev/null 2>&1 && ! command -v cargo >/dev/null 2>&1; then
  echo "   → rustup"
  curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y --no-modify-path
else
  echo "   → rust already installed (skip)"
fi

# --- Rust environment repair + toolchain auto-update ---------------------------
# 1) Prune any *dangling* ~/.cargo/bin proxy symlinks. These appear when a prior
#    Homebrew keg-only rustup (whose formula was renamed rustup-init → rustup)
#    left cargo/rustc/... symlinked to a target that no longer exists. Official
#    rustup proxies are live symlinks to a real ~/.cargo/bin/rustup, so a
#    dangling-only check never touches a healthy install.
if [[ -d "$HOME/.cargo/bin" ]]; then
  for _p in cargo cargo-clippy cargo-fmt cargo-miri clippy-driver rls \
            rust-analyzer rust-gdb rust-gdbgui rust-lldb rustc rustdoc \
            rustfmt rustup; do
    _f="$HOME/.cargo/bin/$_p"
    if [[ -L "$_f" && ! -e "$_f" ]]; then
      rm -f "$_f" && echo "   → pruned dangling rust proxy: $_p"
    fi
  done
  unset _p _f
fi

# 2) Weekly `rustup update` launchd agent. rustup only self-updates its manager;
#    the toolchain (rustc/cargo) is refreshed by `rustup update`, which nothing
#    else runs. Idempotent: (re)writes the script + plist and reloads.
if command -v launchctl >/dev/null 2>&1; then
  echo "   → rustup weekly auto-update agent"
  _label="com.chris.rustup-update"
  _agent="$HOME/.local/bin/rustup-auto-update.sh"
  _plist="$HOME/Library/LaunchAgents/${_label}.plist"
  mkdir -p "$HOME/.local/bin" "$HOME/Library/LaunchAgents" "$HOME/Library/Logs"
  cat > "$_agent" <<'AGENT'
#!/bin/zsh
# Weekly Rust toolchain update (launchd: com.chris.rustup-update).
# Prefers official rustup in ~/.cargo/bin; falls back to a brew keg-only rustup.
export PATH="$HOME/.cargo/bin:/opt/homebrew/opt/rustup/bin:$PATH"
echo "===== $(date '+%Y-%m-%d %H:%M:%S') — rustup update ====="
rustup update
echo "----- active toolchain now: -----"
rustc --version
echo
AGENT
  chmod +x "$_agent"
  cat > "$_plist" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>${_label}</string>
    <key>ProgramArguments</key>
    <array>
        <string>/bin/zsh</string>
        <string>${_agent}</string>
    </array>
    <key>StartCalendarInterval</key>
    <dict>
        <key>Weekday</key><integer>1</integer>
        <key>Hour</key><integer>10</integer>
        <key>Minute</key><integer>0</integer>
    </dict>
    <key>RunAtLoad</key>
    <false/>
    <key>StandardOutPath</key>
    <string>${HOME}/Library/Logs/rustup-update.log</string>
    <key>StandardErrorPath</key>
    <string>${HOME}/Library/Logs/rustup-update.log</string>
</dict>
</plist>
PLIST
  launchctl bootout "gui/$(id -u)/${_label}" >/dev/null 2>&1 || true
  launchctl bootstrap "gui/$(id -u)" "$_plist" >/dev/null 2>&1 \
    || launchctl load -w "$_plist" >/dev/null 2>&1 || true
  unset _label _agent _plist
fi
# --- end Rust repair -----------------------------------------------------------

link_dotfiles

[[ -f "$HOME/secrets.sh" ]] || touch "$HOME/secrets.sh"

# Hidden secrets dir + archive target for `ssync` (specstory chat history).
# `ssync` also mkdir -p's this, but create it here so the location exists on a
# fresh box before any sync runs. Override the archive root via $SSYNC_ARCHIVE.
mkdir -p "$HOME/.secrets/agent-chats"

# fzf's installer rewrites ~/.zshrc unless we use --no-update-rc. ~/.zshrc
# already does `source <(fzf --zsh)` at startup, so the rc rewrite would only
# add a duplicate block.
if [[ -x "$(brew --prefix)/opt/fzf/install" ]]; then
  echo "🔍 Configuring fzf (key bindings + completion, no rc rewrite)…"
  "$(brew --prefix)/opt/fzf/install" --key-bindings --completion --no-update-rc --no-bash --no-fish
fi

mkdir -p ~/.zsh
touch ~/.zsh/history

ensure_login_shell

echo "✨ Installation complete!"
echo "Sync later with: git pull && ./install.sh --link-only"

echo "
🔧 Maintenance:
- brew update && brew upgrade
- tldr --update
"
