if [ -z "$TMUX" ]; then
  exec tmux new-session -A -s macShell
fi

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
export GITROB_ACCESS_TOKEN=4c6488d319611cc266c43894359eeaa9cc4b9fd0
export CENSYS_API_ID=3d666534-b970-491c-904a-fbfb2f1a2e35
export CENSYS_API_SECRET=igV9Q5OQ2R0DtDAD78bs8J61zQIKcjKx
export PATH="/home/linuxbrew/.linuxbrew/bin:$PATH"
export PATH="/usr/local/sbin:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin:/opt/X11/bin"
export PATH=~/.local/bin:$PATH
export PATH=/usr/local/bin:$PATH
export PATH=~/.npm-packages/bin:$PATH
export PATH=~/.npm-packages/lib/node_modules/n/bin:$PATH
export PATH=/usr/local/sbin:$PATH
export PATH=/usr/local/opt/qt/bin:$PATH
export PATH=/usr/local/opt/bison/bin:$PATH
export PATH="/usr/local/opt/openssl/bin:$PATH"
export PATH="/usr/local/opt/curl/bin:$PATH"
export PATH="/usr/local/opt/ncurses/bin:$PATH"
export PATH="/usr/local/opt/libressl/bin:$PATH"
export PATH="/usr/local/opt/curl/bin:$PATH"
export PATH="/snap/bin:$PATH"
export PATH="/root/go/bin:$PATH"
export GOPATH=$HOME/go/
export GIO_EXTRA_MODULES=/usr/lib/x86_64-linux-gnu/gio/modules/
export TERM=xterm-256color
export LESSOPEN="| $(which highlight) %s --out-format xterm256 --line-numbers --quiet --force --style moria"
export LESS=" -R"
export PATH=/bin/lscript:$PATH
export MANPATH="/usr/local/man:$MANPATH"
export LANG=en_US.UTF-8
export ARCHFLAGS="-arch x86_64"
export FZF_DEFAULT_COMMAND='rg --hidden --no-ignore -l ""'
export PATH=$PATH:/opt/gists
export PATH="/Users/farrc060/bin:$PATH"

ZSH_THEME="powerlevel10k/powerlevel10k"
POWERLEVEL9K_COLOR_SCHEME='light'
POWERLEVEL9K_MODE='nerdfont-complete'
POWERLEVEL9K_SHORTEN_DIR_LENGTH='1'
POWERLEVEL9K_SHORTEN_DELIMITER='..'
POWERLEVEL9K_SHORTEN_STRATEGY="truncate_to_unique"
POWERLEVEL9K_PROMPT_ON_NEWLINE=true
POWERLEVEL9K_PROMPT_ADD_NEWLINE=true
POWERLEVEL9K_LEFT_SEGMENT_SEPARATOR=$'\uE0C6'
POWERLEVEL9K_RIGHT_SEGMENT_SEPARATOR=$'\uE0C7'
POWERLEVEL9K_LEFT_SUBSEGMENT_SEPARATOR=$'\uE0C6'
POWERLEVEL9K_RIGHT_SUBSEGMENT_SEPARATOR=$'\uE0C7'
POWERLEVEL9K_MULTILINE_FIRST_PROMPT_PREFIX="%F{blue}\u256D\u2500%F{white}"
POWERLEVEL9K_MULTILINE_LAST_PROMPT_PREFIX="%F{blue}\u2570\uf460%F{white} "
POWERLEVEL9K_VCS_MODIFIED_BACKGROUND="clear"
POWERLEVEL9K_VCS_UNTRACKED_BACKGROUND="clear"
# POWERLEVEL9K_VCS_MODIFIED_FOREGROUND="yellow"
# POWERLEVEL9K_VCS_UNTRACKED_FOREGROUND="yellow"
POWERLEVEL9K_DIR_HOME_BACKGROUND="clear"
# #POWERLEVEL9K_DIR_HOME_FOREGROUND="blue"
POWERLEVEL9K_DIR_HOME_SUBFOLDER_BACKGROUND="clear"
# #POWERLEVEL9K_DIR_HOME_SUBFOLDER_FOREGROUND="blue"
POWERLEVEL9K_DIR_WRITABLE_FORBIDDEN_BACKGROUND="clear"
# #POWERLEVEL9K_DIR_WRITABLE_FORBIDDEN_FOREGROUND="red"
POWERLEVEL9K_DIR_DEFAULT_BACKGROUND="clear"
# #POWERLEVEL9K_DIR_DEFAULT_FOREGROUND="black"
POWERLEVEL9K_ROOT_INDICATOR_BACKGROUND="red"
# POWERLEVEL9K_ROOT_INDICATOR_FOREGROUND="black"
POWERLEVEL9K_STATUS_OK_BACKGROUND="clear"
# POWERLEVEL9K_STATUS_OK_FOREGROUND="green"
POWERLEVEL9K_STATUS_ERROR_BACKGROUND="clear"
# POWERLEVEL9K_STATUS_ERROR_FOREGROUND="red"
POWERLEVEL9K_TIME_BACKGROUND="clear"
#POWERLEVEL9K_TIME_FOREGROUND="cyan"
POWERLEVEL9K_COMMAND_EXECUTION_TIME_BACKGROUND='magenta'
# POWERLEVEL9K_COMMAND_EXECUTION_TIME_FOREGROUND='magenta'
POWERLEVEL9K_BACKGROUND_JOBS_BACKGROUND='clear'
# POWERLEVEL9K_BACKGROUND_JOBS_FOREGROUND='green'
POWERLEVEL9K_IP_BACKGROUND="clear"
# POWERLEVEL9K_IP_FOREGROUND='yellow'
POWERLEVEL9K_HISTORY_BACKGROUND='clear'
# POWERLEVEL9K_HISTORY_FOREGROUND='white'
POWERLEVEL9K_LEFT_PROMPT_ELEMENTS=(dir dir_writable_joined virtualenv anaconda pyenv)
POWERLEVEL9K_TIME_FORMAT="%D{%H:%M:%S • %d.%m.%y}"
POWERLEVEL9K_RIGHT_PROMPT_ELEMENTS=(status history command_execution_time time ip)

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

[[ -s "/etc/grc.zsh"  ]] && source /etc/grc.zsh
fpath=(~/.zsh.d/ $fpath)

[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh

autoload -Uz compinit
compinit

# https://extensions.gnome.org/extension/1732/gtk-title-bar/

# To customize prompt, run `p10k configure` or edit ~/.p10k.zsh.
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh