###############################
# Early Initialization - P10k
###############################
# Enable Powerlevel10k instant prompt. Should stay close to the top.
# Initialization code that may require console input (password prompts, [y/n] confirmations, etc.)
# must go above this block; everything else may go below.
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

###############################
# Core Environment Variables
###############################
# Shell basics
export ZSH=~/.oh-my-zsh          # Oh My Zsh installation path
export TERM=xterm-256color       # Enable 256 color support
export LANG=en_US.UTF-8          # Default language setting
export ARCHFLAGS="-arch x86_64"  # Architecture-specific flags

# Default editors
export EDITOR=vim
export VISUAL=vim

# Search and display settings
export GREP_OPTIONS='--color=always'  # Always colorize grep output
export ACK_PAGER_COLOR="{$PAGER:-less -R}"  # Colorized ack output
export LESS='-F -i -J -M -R -W -x4 -X -z-4'  # Improved less behavior:
                                             # -F: quit if one screen
                                             # -i: ignore case in searches
                                             # -J: show status column
                                             # -M: show detailed prompt
                                             # -R: handle ANSI colors
                                             # -W: highlight first new line after forward movement
                                             # -x4: tabs are 4 characters
                                             # -X: don't clear screen on exit
                                             # -z-4: keep 4 lines overlap when scrolling

# FZF (Fuzzy Finder) configuration
export FZF_DEFAULT_COMMAND='ag --hidden -g ""'  # Use silver searcher for FZF
export FZF_DEFAULT_OPTS="
  --height 40%                   # Use 40% of screen height
  --layout=reverse              # List matches from top to bottom
  --border                      # Add border around the finder
  --info=inline                 # Show info inline with results
  --preview='[[ \$(file --mime {}) =~ binary ]] && 
            echo {} is a binary file || 
            (bat --style=numbers --color=always {} || cat {}) 2>/dev/null | 
            head -300'           # Show file preview with syntax highlighting
  --preview-window='right:hidden:wrap'  # Preview window configuration
  --bind='f3:execute(bat --style=numbers {} || less -f {}),
         f2:toggle-preview,
         ctrl-d:half-page-down,
         ctrl-u:half-page-up,
         ctrl-y:execute-silent(echo {+} | pbcopy)'  # Custom key bindings
"

# Homebrew settings
export HOMEBREW_NO_ENV_HINTS=1  # Disable Homebrew environment hints

###############################
# Path Configuration
###############################
# Ensure paths are unique with typeset
typeset -U path
path=(
    # System paths
    /usr/local/{sbin,bin}      # Local system binaries
    /usr/{bin,sbin}            # System binaries
    /{bin,sbin}                # Essential system binaries
    
    # User-specific paths
    ~/Library/Python/3.8/bin   # Python user binaries
    ~/.local/bin               # Local user binaries
    ~/.npm-packages/{bin,lib/node_modules/n/bin}  # NPM packages
    
    # Additional tool paths
    /bin/lscript               # Custom scripts
    /usr/local/anaconda3/bin   # Anaconda
    $path                      # Existing path entries
)
export PATH

###############################
# Language-Specific Settings
###############################
# Man pages
export MANPATH=/usr/local/man:$MANPATH

# Golang configuration
export GOROOT=/usr/local/go
export GOPATH=$HOME/go
path+=($GOPATH/bin $GOROOT/bin)

# Mono framework
export MONO_GAC_PREFIX="/usr/local"

# Bun JavaScript runtime
export BUN_INSTALL="$HOME/.bun"
path+=($BUN_INSTALL/bin)

###############################
# History Configuration
###############################
HISTFILE=~/.zsh/history        # History file location
HISTSIZE=10000000              # Maximum events in internal history
SAVEHIST=10000000              # Maximum events in history file
HISTORY_IGNORE="(ls|cd|pwd|exit|cd)*"  # Commands to ignore
HIST_STAMPS="yyyy-mm-dd"       # Timestamp format

# History Options
setopt APPEND_HISTORY          # Append to history instead of overwriting
setopt EXTENDED_HISTORY        # Save timestamp and duration
setopt SHARE_HISTORY           # Share history between sessions

# Duplicate Management
setopt HIST_IGNORE_ALL_DUPS   # Remove older duplicate entries
setopt HIST_IGNORE_DUPS       # Don't record duplicates
setopt HIST_IGNORE_SPACE      # Ignore commands starting with space
setopt HIST_SAVE_NO_DUPS      # Don't save duplicates
setopt HIST_FIND_NO_DUPS      # Don't show duplicates in search

# History Optimization
setopt HIST_REDUCE_BLANKS     # Remove superfluous blanks
setopt HIST_VERIFY            # Don't execute immediately upon expansion
setopt INC_APPEND_HISTORY     # Add commands as they are typed
setopt NO_HIST_BEEP           # No beep when accessing non-existent history

###############################
# Oh-My-Zsh Configuration
###############################
ZSH_THEME="powerlevel10k/powerlevel10k"

# Essential plugins for daily use
plugins=(
    git                      # Git integration and aliases
    history-substring-search # Better history search
    colored-man-pages        # Colored man pages
    F-Sy-H                   # Syntax highlighting
    command-not-found        # Suggest packages for unknown commands
    zsh-autosuggestions      # Command suggestions
    you-should-use           # Remind about aliases
)

# NVM (Node Version Manager) lazy loading
lazy_load_nvm() {
    unset -f nvm node npm
    export NVM_DIR="$HOME/.nvm"
    [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
}

# Create lazy load triggers for Node-related commands
for cmd in nvm node npm; do
    eval "${cmd}() { lazy_load_nvm; ${cmd} \$@ }"
done

# Update behavior
zstyle ':omz:update' mode auto
ZSH_CUSTOM_AUTOUPDATE_QUIET=true

# General shell behavior
DISABLE_AUTO_TITLE=true        # Don't auto-set terminal title
HYPHEN_INSENSITIVE=true       # Treat - and _ interchangeably
ENABLE_CORRECTION=false       # Disable command correction
COMPLETION_WAITING_DOTS=true  # Show dots during completion

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

# Better word navigation (Alt+arrow keys)
bindkey "^[f" forward-word
bindkey "^[b" backward-word

# Ctrl+Delete to delete word forward
bindkey "^[[3;5~" kill-word

# Ctrl+Backspace to delete word backward
bindkey '^H' backward-kill-word

# Home/End keys
bindkey "^[[H" beginning-of-line
bindkey "^[[F" end-of-line

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

###############################
# Performance Improvements
###############################
# Add near the top after environment variables
# Faster git completion
__git_files () { 
    _wanted files expl 'local files' _files     
}

# Disable automatic updates for better startup time
DISABLE_AUTO_UPDATE=true

###############################
# Better Terminal Experience
###############################
# Add near the end
# Command execution time stamp shown in the history
HIST_STAMPS="mm/dd/yyyy"

# Report CPU usage for commands running longer than 10 seconds
REPORTTIME=10

# Automatically list directory contents on 'cd'
auto-ls() { ls; }
chpwd_functions=(${chpwd_functions[@]} "auto-ls")