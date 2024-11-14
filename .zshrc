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
  --height 40%
  --layout=reverse
  --border
  --info=inline
  --preview='[[ \$(file --mime {}) =~ binary ]] && 
            echo {} is a binary file || 
            (bat --style=numbers --color=always {} || cat {}) 2>/dev/null | 
            head -300'
  --preview-window='right:hidden:wrap'
  --bind='f3:execute(bat --style=numbers {} || less -f {})'
  --bind='ctrl-p:toggle-preview'
  --bind='ctrl-d:half-page-down'
  --bind='ctrl-u:half-page-up'
  --bind='ctrl-y:execute-silent(echo {+} | pbcopy)'
"

# Homebrew settings
export HOMEBREW_NO_ENV_HINTS=1  # Disable Homebrew environment hints

# Add these near the top of your environment variables section
export LDFLAGS="-L/usr/local/opt/openssl@1.1/lib"
export CPPFLAGS="-I/usr/local/opt/openssl@1.1/include"
export PKG_CONFIG_PATH="/usr/local/opt/openssl@1.1/lib/pkgconfig"
export PYTHON_BUILD_HOMEBREW_OPENSSL_FORMULA="openssl@1.1"

###############################
# Path Configuration
###############################
# Ensure paths are unique with typeset
typeset -U path
path=(
    /usr/local/opt/openssl@1.1/bin   # Make sure this is first
    # System paths
    /usr/local/opt/openssl@1.1/bin   # Brew OpenSSL
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
    ~/.cargo/bin               # Rust
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
HISTORY_IGNORE="(pwd|exit)*"  # Commands to ignore
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
# Plugin Management
###############################
# Plugin Management
plug() {
    if [[ ! -f "$HOME/.local/share/zap/zap.zsh" ]]; then
        echo "Installing zap..."
        mkdir -p "$HOME/.local/share/zap"
        git clone https://github.com/zap-zsh/zap.git "$HOME/.local/share/zap"
        source "$HOME/.local/share/zap/zap.zsh"
    fi
    
    local plugin_dir="$HOME/.local/share/zsh/plugins/${1:t}"
    if [[ ! -d "$plugin_dir" ]]; then
        git clone "https://github.com/${1}" "$plugin_dir"
    fi
    source "$plugin_dir/${1:t}.plugin.zsh" 2>/dev/null || \
    source "$plugin_dir/${1:t}.zsh" 2>/dev/null || \
    source "$plugin_dir/${1:t}.sh" 2>/dev/null
}

# Initialize zap if it exists
[ -f "$HOME/.local/share/zap/zap.zsh" ] && source "$HOME/.local/share/zap/zap.zsh"

# Core plugins
plug "zsh-users/zsh-autosuggestions"
plug "zdharma-continuum/fast-syntax-highlighting"
plug "zsh-users/zsh-history-substring-search"
plug "MichaelAquilina/zsh-you-should-use"
plug "MichaelAquilina/zsh-autoswitch-virtualenv"

source ~/dotfiles/completions.zsh

# Load completions
autoload -Uz compinit
if [ $(date +'%j') != $(stat -f '%Sm' -t '%j' ~/.zcompdump) ]; then
  compinit
else
  compinit -C
fi

# Better completion settings
zstyle ':completion:*' menu select
zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}'
zstyle ':completion:*' list-colors "${(s.:.)LS_COLORS}"
zstyle ':completion:*' verbose yes
zstyle ':completion:*:descriptions' format '%B%d%b'
zstyle ':completion:*:messages' format '%d'
zstyle ':completion:*:warnings' format 'No matches for: %d'
zstyle ':completion:*:corrections' format '%B%d (errors: %e)%b'

# Remove Oh-My-Zsh specific configurations
unset ZSH
unset ZSH_THEME

###############################
# Source Configurations
###############################
source ~/secrets.sh

# Global flag to track if dotfiles are loaded
DOTFILES_LOADED=0

# Function to load dotfiles
function load_dotfiles() {
    source ~/dotfiles/.zsh.aliases
    source ~/dotfiles/.zsh.functions
    DOTFILES_LOADED=1
}

# Initial load of dotfiles
load_dotfiles

# Async reload of dotfiles for future updates
{
    sleep 0.1
    load_dotfiles
} &!

# Replace with this simpler approach if you still want the wrappers
for cmd in g d k; do  # Only wrap shorthand commands
    eval "function $cmd() { [[ \$DOTFILES_LOADED -eq 0 ]] && load_dotfiles; command \$cmd \$@ }"
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
# [[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh

# Lazy load conda
conda() {
    unfunction conda
    # Add OpenSSL to path
    export PATH="/usr/local/opt/openssl@1.1/bin:/usr/local/anaconda3/bin:$PATH"
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

# # Lazy load less intensive tools
# {
#     # FZF
#     source <(fzf --zsh)
    
#     # iTerm2
#     test -e "${HOME}/.iterm2_shell_integration.zsh" && source "${HOME}/.iterm2_shell_integration.zsh"
    
#     # Bun completions
#     [ -s "$HOME/.bun/_bun" ] && source "$HOME/.bun/_bun"
    
#     # Cargo
#     [ -f "$HOME/.cargo/env" ] && source "$HOME/.cargo/env"
    
#     # Zoxide
#     eval "$(zoxide init zsh)"
# } &!


# FZF
source <(fzf --zsh)

# iTerm2
test -e "${HOME}/.iterm2_shell_integration.zsh" && source "${HOME}/.iterm2_shell_integration.zsh"

# Bun completions
[ -s "$HOME/.bun/_bun" ] && source "$HOME/.bun/_bun"

# Cargo
[ -f "$HOME/.cargo/env" ] && source "$HOME/.cargo/env"

# Zoxide
eval "$(zoxide init zsh)"


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

export STARSHIP_CONFIG=~/dotfiles/config/starship/starship.toml
eval "$(starship init zsh)"

###############################
# Vi Mode Configuration
###############################
# Enable vi mode
bindkey -v

# Reduce ESC delay to 0.1 seconds
export KEYTIMEOUT=1

# Use vim keys in tab complete menu
bindkey -M menuselect 'h' vi-backward-char
bindkey -M menuselect 'k' vi-up-line-or-history
bindkey -M menuselect 'l' vi-forward-char
bindkey -M menuselect 'j' vi-down-line-or-history

# Cursor style options:
# '\e[0 q' - blinking block
# '\e[1 q' - blinking block (default)
# '\e[2 q' - steady block
# '\e[3 q' - blinking underline
# '\e[4 q' - steady underline
# '\e[5 q' - blinking beam
# '\e[6 q' - steady beam

# Change cursor shape for different vi modes
function zle-keymap-select {
  if [[ ${KEYMAP} == vicmd ]] ||
     [[ $1 = 'block' ]]; then
    # Normal mode cursor options:
    echo -ne '\e[1 q'  # blinking block
    # echo -ne '\e[0 q'  # blinking block (alternative)
    # echo -ne '\e[2 q'  # steady block
    # echo -ne '\e[3 q'  # blinking underline
    # echo -ne '\e[4 q'  # steady underline
  elif [[ ${KEYMAP} == main ]] ||
       [[ ${KEYMAP} == viins ]] ||
       [[ ${KEYMAP} = '' ]] ||
       [[ $1 = 'beam' ]]; then
    # Insert mode cursor options:
    echo -ne '\e[5 q'  # blinking beam
    # echo -ne '\e[6 q'  # steady beam
    # echo -ne '\e[3 q'  # blinking underline
    # echo -ne '\e[4 q'  # steady underline
  fi
}
zle -N zle-keymap-select

# Initial cursor style options:
echo -ne '\e[5 q'  # blinking beam
# echo -ne '\e[6 q'  # steady beam
# echo -ne '\e[1 q'  # blinking block
# echo -ne '\e[2 q'  # steady block
# echo -ne '\e[3 q'  # blinking underline
# echo -ne '\e[4 q'  # steady underline

# Cursor style for new prompt options:
precmd() { 
    echo -ne '\e[5 q'  # blinking beam
    # echo -ne '\e[6 q'  # steady beam
    # echo -ne '\e[1 q'  # blinking block
    # echo -ne '\e[2 q'  # steady block
    # echo -ne '\e[3 q'  # blinking underline
    # echo -ne '\e[4 q'  # steady underline
}

# Cursor style for each command options:
preexec() { 
    echo -ne '\e[5 q'  # blinking beam
    # echo -ne '\e[6 q'  # steady beam
    # echo -ne '\e[1 q'  # blinking block
    # echo -ne '\e[2 q'  # steady block
    # echo -ne '\e[3 q'  # blinking underline
    # echo -ne '\e[4 q'  # steady underline
}
