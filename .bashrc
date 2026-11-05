# ~/.bashrc — deliberately vanilla bash.
#
# AI agents source or snapshot this file, so it must behave like a stock
# system: no aliases shadowing real commands, no cd/zoxide hooks, no pagers,
# no prompt frameworks. Your real interactive shell is zsh (via iTerm).

[ -r "$HOME/.profile" ] && . "$HOME/.profile"

# Everything below is for interactive bash only.
case $- in *i*) ;; *) return ;; esac

HISTFILE="$HOME/.bash_history"
HISTSIZE=10000
HISTFILESIZE=20000
HISTCONTROL=ignoreboth
shopt -s histappend checkwinsize
PS1='\w \$ '

# Machine-local history policy (optional). No-op if absent.
[ -r "$HOME/.config/privacy/bash-history.sh" ] && . "$HOME/.config/privacy/bash-history.sh"
