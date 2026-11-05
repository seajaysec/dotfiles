# ~/.profile — environment for bash / sh (the system login shell).
#
# This is what Claude Code, Codex, Cursor, GUI apps and scripts see. Keep it
# boring: PATH + a few standard vars. No aliases, no functions, no pagers, no
# hooks. Personal interactive niceties live in zsh (~/.zshrc), which iTerm runs.
# Safe to source repeatedly (PATH is de-duplicated).

# Privacy (machine-local, optional): telemetry opt-outs, REPL history off. No-op if absent.
[ -r "$HOME/.config/privacy/env.sh" ] && . "$HOME/.config/privacy/env.sh"

export BASH_SILENCE_DEPRECATION_WARNING=1   # silence macOS "default shell is now zsh"
export LANG="${LANG:-en_US.UTF-8}"
export EDITOR=vim
export VISUAL=vim
export DOTFILES="${DOTFILES:-$HOME/dotfiles}"

# Homebrew (sets HOMEBREW_PREFIX, MANPATH, INFOPATH, PATH)
export HOMEBREW_NO_ENV_HINTS=1
if [ -x /opt/homebrew/bin/brew ]; then
  eval "$(/opt/homebrew/bin/brew shellenv)"
elif [ -x /usr/local/bin/brew ]; then
  eval "$(/usr/local/bin/brew shellenv)"
fi

# Language toolchains
export GOPATH="$HOME/go"
export GOBIN="$GOPATH/bin"   # `go install` drops binaries here (on PATH below)
export BUN_INSTALL="$HOME/.bun"
export LAUNCH_HOME="$HOME/.launch"
unset GOROOT   # must follow whichever `go` is on PATH
export UV_PYTHON_PREFERENCE=only-managed   # uv uses only its own Pythons

# PATH — same order as zsh, then whatever the parent passed in, de-duplicated.
PATH="$HOME/.local/bin:$LAUNCH_HOME/bin:/opt/homebrew/bin:/opt/homebrew/sbin:/opt/homebrew/opt/openssl@3/bin:/usr/local/bin:/usr/local/sbin:/usr/bin:/usr/sbin:/bin:/sbin:$HOME/.npm-packages/bin:$HOME/.cargo/bin:$HOME/.dotnet/tools:$GOPATH/bin:$BUN_INSTALL/bin:${PATH:+$PATH:}$HOME/.lmstudio/bin:$HOME/.cache/lm-studio/bin"
PATH="$(printf '%s' "$PATH" | awk -v RS=: -v ORS=: 'length && !seen[$0]++' | sed 's/:$//')"
export PATH

# Ghidra / REA (bash + agents; zsh gets GHIDRA_INSTALL_DIR from .zshenv). Only where installed.
[ -d /opt/homebrew/opt/ghidra/libexec ] && export GHIDRA_INSTALL_DIR="/opt/homebrew/opt/ghidra/libexec"
[ -z "${JAVA_HOME:-}" ] && [ -d /Library/Java/JavaVirtualMachines/temurin-27.jdk ] && \
  export JAVA_HOME="/Library/Java/JavaVirtualMachines/temurin-27.jdk/Contents/Home"

# API keys / tokens (shared with zsh)
[ -f "$HOME/secrets.sh" ] && . "$HOME/secrets.sh"
export NAVI_HOME="$HOME/.navi"
export NAVI_ACCESS_KEY="${VISION_TIO_ACCESS_KEY:-}"
export NAVI_SECRET_KEY="${VISION_TIO_SECRET_KEY:-}"
