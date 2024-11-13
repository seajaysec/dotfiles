###############################
# Early Initialization
###############################
# Enable Powerlevel10k instant prompt (must stay at top)
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

###############################
# Environment Variables
###############################
# Shell
export ZSH=~/.oh-my-zsh
export TERM=xterm-256color
export LANG=en_US.UTF-8
export ARCHFLAGS="-arch x86_64"

# Editors
export EDITOR=vim
export VISUAL=vim

# Search and Display
export GREP_OPTIONS='--color=always'
export ACK_PAGER_COLOR="{$PAGER:-less -R}"
export LESSOPEN="| $(which highlight) %s --out-format xterm256 --line-numbers --quiet --force --style moria"
export LESS=" -R"
export FZF_DEFAULT_COMMAND='ag --hidden -g ""'

# Homebrew
export HOMEBREW_NO_ENV_HINTS=1

# Path Configuration (consolidated)
path=(
    /usr/local/sbin
    /usr/local/bin
    /usr/bin
    /bin
    /usr/sbin
    /sbin
    ~/Library/Python/3.8/bin
    ~/.local/bin
    ~/.npm-packages/bin
    ~/.npm-packages/lib/node_modules/n/bin
    /bin/lscript
    /usr/local/anaconda3/bin
    $path
)
export PATH

# Man pages
export MANPATH=/usr/local/man:$MANPATH

# Golang
export GOROOT=/usr/local/go
export GOPATH=$HOME/go
export PATH=$GOPATH/bin:$GOROOT/bin:$PATH

# Mono
export MONO_GAC_PREFIX="/usr/local"

# Bun
export BUN_INSTALL="$HOME/.bun"
export PATH="$BUN_INSTALL/bin:$PATH"

###############################
# Oh-My-Zsh Configuration
###############################
ZSH_THEME="powerlevel10k/powerlevel10k"

plugins=(
    tmux 
    history-substring-search 
    git 
    colored-man-pages 
    colorize 
    F-Sy-H 
    autoupdate 
    command-not-found 
    cp 
    emoji 
    man 
    nmap 
    sublime 
    sudo 
    vi-mode 
    vim-interaction 
    zsh-autosuggestions 
    autoswitch_virtualenv 
    you-should-use 
    $plugins
)

# Update settings
zstyle ':omz:update' mode auto
ZSH_CUSTOM_AUTOUPDATE_QUIET=true

# General settings
DISABLE_AUTO_TITLE=true
HYPHEN_INSENSITIVE=true
ENABLE_CORRECTION=false
COMPLETION_WAITING_DOTS=true

###############################
# History Configuration
###############################
HISTFILE=~/.zsh/history
HISTSIZE=10000000
SAVEHIST=10000000
HISTORY_IGNORE="(ls|cd|pwd|exit|cd)*"
HIST_STAMPS="yyyy-mm-dd"

setopt APPEND_HISTORY
setopt EXTENDED_HISTORY
setopt HIST_FIND_NO_DUPS
setopt HIST_IGNORE_ALL_DUPS
setopt HIST_IGNORE_DUPS
setopt HIST_IGNORE_SPACE
setopt HIST_NO_STORE
setopt HIST_REDUCE_BLANKS
setopt HIST_SAVE_NO_DUPS
setopt HIST_VERIFY
setopt INC_APPEND_HISTORY
setopt NO_HIST_BEEP
setopt SHARE_HISTORY

###############################
# Source Configurations
###############################
source $ZSH/oh-my-zsh.sh
source ~/dotfiles/.zsh.aliases
source ~/dotfiles/.zsh.functions
source ~/secrets.sh

###############################
# Key Bindings
###############################
bindkey '^[[A' history-substring-search-up
bindkey '^[[B' history-substring-search-down

###############################
# Completion
###############################
autoload -Uz compinit
compinit

###############################
# External Tools Integration
###############################
# Powerlevel10k
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh

# FZF
[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh

# Conda
__conda_setup="$('/usr/local/anaconda3/bin/conda' 'shell.zsh' 'hook' 2> /dev/null)"
if [ $? -eq 0 ]; then
    eval "$__conda_setup"
else
    if [ -f "/usr/local/anaconda3/etc/profile.d/conda.sh" ]; then
        . "/usr/local/anaconda3/etc/profile.d/conda.sh"
    else
        export PATH="/usr/local/anaconda3/bin:$PATH"
    fi
fi
unset __conda_setup

# iTerm2
test -e "${HOME}/.iterm2_shell_integration.zsh" && source "${HOME}/.iterm2_shell_integration.zsh"

# Bun completions
[ -s "/Users/Chris.J.Farrell/.bun/_bun" ] && source "/Users/Chris.J.Farrell/.bun/_bun"

# Cargo
. "$HOME/.cargo/env"

# Zoxide
eval "$(zoxide init zsh)"