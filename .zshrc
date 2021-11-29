# Enable Powerlevel10k instant prompt. Should stay close to the top of ~/.zshrc.
# Initialization code that may require console input (password prompts, [y/n]
# confirmations, etc.) must go above this block, everything else may go below.
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

export ZSH=~/.oh-my-zsh
export EDITOR=vim
export VISUAL=vim
export GREP_OPTIONS='--color=always'
export ACK_PAGER_COLOR="{$PAGER:-less -R}"
export MONO_GAC_PREFIX="/usr/local"
export PATH=/usr/local/bin:$PATH
export PATH=/usr/local/sbin:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin:$PATH
export PATH=~/.local/bin:$PATH
export PATH=~/.npm-packages/bin:$PATH
export PATH=~/.npm-packages/lib/node_modules/n/bin:$PATH
export PATH=/usr/local/sbin:$PATH
export GOPATH=$HOME/go/
export TERM=xterm-256color
export LESSOPEN="| $(which highlight) %s --out-format xterm256 --line-numbers --quiet --force --style moria"
export LESS=" -R"
export PATH=/bin/lscript:$PATH
export MANPATH="/usr/local/man:$MANPATH"
export LANG=en_US.UTF-8
export ARCHFLAGS="-arch x86_64"
export FZF_DEFAULT_COMMAND='rg --hidden --no-ignore -l ""'

ZSH_THEME="powerlevel10k/powerlevel10k"

plugins=(tmux history-substring-search git colored-man-pages colorize fast-syntax-highlighting autoupdate command-not-found cp emoji man nmap sublime sudo vi-mode vim-interaction zsh-autosuggestions autoswitch_virtualenv you-should-use $plugins)

#ZSH_TMUX_AUTOSTART="true"
ENABLE_CORRECTION="false"
COMPLETION_WAITING_DOTS="false"
DISABLE_AUTO_TITLE="true"
ZSH_CUSTOM_AUTOUPDATE_QUIET="true"

source $ZSH/oh-my-zsh.sh
source ~/dotfiles/.zsh.aliases
source ~/dotfiles/.zsh.functions

bindkey '^[[A' history-substring-search-up
bindkey '^[[B' history-substring-search-down

# Enable autocompletion
autoload -Uz compinit
compinit

# https://extensions.gnome.org/extension/1732/gtk-title-bar/

# To customize prompt, run `p10k configure` or edit ~/.p10k.zsh.
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh