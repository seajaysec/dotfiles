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
export LESS=" -R"
export FZF_DEFAULT_COMMAND='ag --hidden -g ""'

# Homebrew
export HOMEBREW_NO_ENV_HINTS=1

# Path Configuration (consolidated)
typeset -U path  # Ensure unique paths
path=(
    /usr/local/{sbin,bin}
    /usr/{bin,sbin}
    /{bin,sbin}
    ~/Library/Python/3.8/bin
    ~/.local/bin
    ~/.npm-packages/{bin,lib/node_modules/n/bin}
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
path+=($GOPATH/bin $GOROOT/bin)

# Mono
export MONO_GAC_PREFIX="/usr/local"

# Bun
export BUN_INSTALL="$HOME/.bun"
path+=($BUN_INSTALL/bin)

###############################
# Oh-My-Zsh Configuration
###############################
ZSH_THEME="powerlevel10k/powerlevel10k"

# Reduce plugin load for faster startup
plugins=(
    git 
    history-substring-search 
    colored-man-pages 
    F-Sy-H 
    command-not-found 
    zsh-autosuggestions 
    you-should-use
)

# Lazy load slower plugins
lazy_load_nvm() {
    unset -f nvm node npm
    export NVM_DIR="$HOME/.nvm"
    [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
}

for cmd in nvm node npm; do
    eval "${cmd}() { lazy_load_nvm; ${cmd} \$@ }"
done

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

setopt APPEND_HISTORY EXTENDED_HISTORY HIST_FIND_NO_DUPS HIST_IGNORE_ALL_DUPS 
setopt HIST_IGNORE_DUPS HIST_IGNORE_SPACE HIST_NO_STORE HIST_REDUCE_BLANKS 
setopt HIST_SAVE_NO_DUPS HIST_VERIFY INC_APPEND_HISTORY NO_HIST_BEEP SHARE_HISTORY

###############################
# Completion Optimization
###############################
# Load completion system faster
autoload -Uz compinit
if [ $(date +'%j') != $(stat -f '%Sm' -t '%j' ~/.zcompdump) ]; then
  compinit
else
  compinit -C
fi

###############################
# Source Configurations
###############################
source $ZSH/oh-my-zsh.sh
source ~/secrets.sh

# Async load aliases and functions with timeout
{
    sleep 0.1  # Small delay to prioritize shell availability
    source ~/dotfiles/.zsh.aliases
    source ~/dotfiles/.zsh.functions
} &!

# Ensure aliases/functions are available if needed immediately
function ensure_dotfiles() {
    # If the background job hasn't completed, source immediately
    if [[ ! -f ~/dotfiles/.zsh.aliases.zwc ]]; then
        source ~/dotfiles/.zsh.aliases
        source ~/dotfiles/.zsh.functions
    fi
    # Remove this function after first use
    unfunction ensure_dotfiles
}

# Create wrapper for common commands that might need aliases/functions
for cmd in g git d docker k kubectl; do
    eval "function $cmd() { ensure_dotfiles; $cmd \$@ }"
done

###############################
# Key Bindings
###############################
bindkey '^[[A' history-substring-search-up
bindkey '^[[B' history-substring-search-down

###############################
# Async Load External Tools
###############################
# Powerlevel10k
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh

# Lazy load conda
conda() {
    unfunction conda
    # Add conda to path
    export PATH="/usr/local/anaconda3/bin:$PATH"
    __conda_setup="$('/usr/local/anaconda3/bin/conda' 'shell.zsh' 'hook' 2> /dev/null)"
    if [ $? -eq 0 ]; then
        eval "$__conda_setup"
    else
        if [ -f "/usr/local/anaconda3/etc/profile.d/conda.sh" ]; then
            . "/usr/local/anaconda3/etc/profile.d/conda.sh"
        fi
    fi
    conda "$@"
}

# Lazy load less intensive tools
{
    # FZF
    [ -f ~/.fzf.zsh ] && source ~/.fzf.zsh
    
    # iTerm2
    test -e "${HOME}/.iterm2_shell_integration.zsh" && source "${HOME}/.iterm2_shell_integration.zsh"
    
    # Bun completions
    [ -s "$HOME/.bun/_bun" ] && source "$HOME/.bun/_bun"
    
    # Cargo
    [ -f "$HOME/.cargo/env" ] && source "$HOME/.cargo/env"
    
    # Zoxide
    eval "$(zoxide init zsh)"
} &!

# Load lessopen last as it's least critical
export LESSOPEN="| $(which highlight) %s --out-format xterm256 --line-numbers --quiet --force --style moria"