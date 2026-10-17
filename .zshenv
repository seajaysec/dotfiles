# Minimal env for every zsh (ARCH-01). Override DOTFILES if the repo is not at ~/dotfiles.
typeset -Ux PATH path
command -v mkdir >/dev/null 2>&1 || export PATH="/usr/bin:/bin:/usr/sbin:/sbin:/opt/homebrew/bin:/usr/local/bin${PATH:+:$PATH}"
export DOTFILES="${DOTFILES:-$HOME/dotfiles}"
# Session name for the `tm` alias. Override per-host via ~/.zshrc.local.
export tmux_session="${tmux_session:-main}"
export EDITOR=vim
export VISUAL=vim

# --- Ghidra: single install via Homebrew formula ---
# In .zshenv (not .zshrc) so non-interactive shells, scripts, and tools
# spawned outside a login shell see it too.
export GHIDRA_INSTALL_DIR=/opt/homebrew/opt/ghidra/libexec
# JDK 21 for Ghidra only; global `java` stays whatever java_home picks.
# JAVA_HOME_GHIDRA -> our wrappers; GHIDRA_CLI_JAVA_HOME -> ghidra-cli.
export JAVA_HOME_GHIDRA=/opt/homebrew/opt/openjdk@21/libexec/openjdk.jdk/Contents/Home
export GHIDRA_CLI_JAVA_HOME="$JAVA_HOME_GHIDRA"

# Privacy: history/telemetry env shared with bash and sh.
[[ -r "$HOME/.config/privacy/env.sh" ]] && source "$HOME/.config/privacy/env.sh"
