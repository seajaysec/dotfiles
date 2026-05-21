# Minimal env for every zsh (ARCH-01). Override DOTFILES if the repo is not at ~/dotfiles.
typeset -Ux PATH path
command -v mkdir >/dev/null 2>&1 || export PATH="/usr/bin:/bin:/usr/sbin:/sbin:/opt/homebrew/bin:/usr/local/bin${PATH:+:$PATH}"
export DOTFILES="${DOTFILES:-$HOME/dotfiles}"
# Session name for the `tm` alias. Override per-host via ~/.zshrc.local.
export tmux_session="${tmux_session:-main}"
export EDITOR=vim
export VISUAL=vim
