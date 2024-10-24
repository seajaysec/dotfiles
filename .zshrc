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
export PATH=~/Library/Python/3.8/bin:$PATH
export PATH=~/.local/bin:$PATH
export PATH=~/.npm-packages/bin:$PATH
export PATH=~/.npm-packages/lib/node_modules/n/bin:$PATH
export PATH=/usr/local/sbin:$PATH
export PATH=/bin/lscript:$PATH
export PATH=/usr/local/anaconda3/bin:$PATH
export MANPATH=/usr/local/man:$MANPATH
export TERM=xterm-256color
export LESSOPEN="| $(which highlight) %s --out-format xterm256 --line-numbers --quiet --force --style moria"
export LESS=" -R"
export LANG=en_US.UTF-8
export ARCHFLAGS="-arch x86_64"
# brew install the_silver_searcher
export FZF_DEFAULT_COMMAND='ag --hidden -g ""'
# Commenting out ripgrep fzf temporarily for testing ag...
# export FZF_DEFAULT_COMMAND='rg --hidden --no-ignore -l ""'
export HOMEBREW_NO_ENV_HINTS=1
# Golang vars
export GOROOT=/usr/local/go
export GOPATH=$HOME/go
export PATH=$GOPATH/bin:$GOROOT/bin:$HOME/.local/bin:$PATH


ZSH_THEME="powerlevel10k/powerlevel10k"

plugins=(tmux history-substring-search git colored-man-pages colorize F-Sy-H autoupdate command-not-found cp emoji man nmap sublime sudo vi-mode vim-interaction zsh-autosuggestions autoswitch_virtualenv you-should-use $plugins)

### OMZ Pre-Source Settings
# Automatic update OMZ without confirmation prompt
zstyle ':omz:update' mode auto
# Quietly update OMZ plugins
ZSH_CUSTOM_AUTOUPDATE_QUIET=true

source $ZSH/oh-my-zsh.sh
source ~/dotfiles/.zsh.aliases
source ~/dotfiles/.zsh.functions
source ~/secrets.sh

HISTSIZE=10000000
SAVEHIST=10000000

HISTFILE=~/.zsh/history # File
HISTORY_IGNORE="(ls|cd|pwd|exit|cd)*"
setopt APPEND_HISTORY        # append to history file (Default)
setopt EXTENDED_HISTORY      # Write the history file in the ':start:elapsed;command' format.
setopt HIST_FIND_NO_DUPS # Don't show duplicates in search
setopt HIST_IGNORE_ALL_DUPS  # Delete an old recorded event if a new event is a duplicate.
setopt HIST_IGNORE_DUPS      # Do not record an event that was just recorded again.
setopt HIST_IGNORE_SPACE     # Do not record an event starting with a space.
setopt HIST_NO_STORE         # Don't store history commands
setopt HIST_REDUCE_BLANKS    # Remove superfluous blanks from each command line being added to the history.
setopt HIST_SAVE_NO_DUPS     # Do not write a duplicate event to the history file.
setopt HIST_VERIFY           # Do not execute immediately upon history expansion.
setopt INC_APPEND_HISTORY    # Write to the history file immediately, not when the shell exits.
setopt NO_HIST_BEEP # Don't beep
setopt SHARE_HISTORY         # Share history between all sessions.
HIST_STAMPS="yyyy-mm-dd"

### OMZ Post-Source Settings
# Oh My Zsh automatically sets the title of your terminal. Stopping that with this.
DISABLE_AUTO_TITLE=true
# Underscores (_) and hyphens (-) will be interchangeable
HYPHEN_INSENSITIVE=true
# Correct command names and filenames passed as arguments? No way, it's annoying.
ENABLE_CORRECTION=false
# Prints a red ellipsis to indicate that Zsh is still processing a completion request.
COMPLETION_WAITING_DOTS=true

bindkey '^[[A' history-substring-search-up
bindkey '^[[B' history-substring-search-down

# Enable autocompletion
autoload -Uz compinit
compinit

# https://extensions.gnome.org/extension/1732/gtk-title-bar/

# To customize prompt, run `p10k configure` or edit ~/.p10k.zsh.
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh
[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh


# Golang vars
export GOROOT=/usr/local/go
export GOPATH=$HOME/go
export PATH=$GOPATH/bin:$GOROOT/bin:$HOME/.local/bin:$PATH

# >>> conda initialize >>>
# !! Contents within this block are managed by 'conda init' !!
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
# <<< conda initialize <<<


test -e "${HOME}/.iterm2_shell_integration.zsh" && source "${HOME}/.iterm2_shell_integration.zsh"



# bun completions
[ -s "/Users/Chris.J.Farrell/.bun/_bun" ] && source "/Users/Chris.J.Farrell/.bun/_bun"

# bun
export BUN_INSTALL="$HOME/.bun"
export PATH="$BUN_INSTALL/bin:$PATH"

. "$HOME/.cargo/env"
eval "$(zoxide init zsh)"