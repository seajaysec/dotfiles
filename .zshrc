###############################
# Core Environment Variables
###############################
export ZSH=~/.oh-my-zsh
export TERM=xterm-256color
export LANG=en_US.UTF-8
export ARCHFLAGS="-arch x86_64"
export GROFF_NO_SGR=1
export EDITOR=vim
export VISUAL=vim
export ACK_PAGER_COLOR="{$PAGER:-bat --paging=always}"
export PAGER='bat --paging=always'
export MANPAGER="sh -c 'col -bx | bat -l man --paging=always'"
unset LESSOPEN

###############################
# FZF (Fuzzy Finder) configuration
###############################
export FZF_DEFAULT_COMMAND='ag --hidden -g ""'
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
  --bind='f3:execute(bat --style=numbers {} || bat {})'
  --bind='ctrl-p:toggle-preview'
  --bind='ctrl-d:half-page-down'
  --bind='ctrl-u:half-page-up'
  --bind='ctrl-y:execute-silent(echo {+} | pbcopy)'
"

###############################
# Homebrew settings
###############################
export HOMEBREW_NO_ENV_HINTS=1
export LDFLAGS="-L/opt/homebrew/opt/openssl@3/lib"
export CPPFLAGS="-I/opt/homebrew/opt/openssl@3/include"
export PKG_CONFIG_PATH="/opt/homebrew/opt/openssl@3/lib/pkgconfig"
export PYTHON_BUILD_HOMEBREW_OPENSSL_FORMULA="openssl@3"

###############################
# Path Configuration
###############################
typeset -U path
path=(
    /opt/homebrew/bin
    /opt/homebrew/opt/openssl@3/bin
    /usr/local/bin
    /usr/local/sbin
    /usr/bin
    /usr/sbin
    /bin
    /sbin
    ~/.local/bin
    ~/.npm-packages/bin
    ~/.npm-packages/lib/node_modules/n/bin
    /bin/lscript
    ~/.cargo/bin
)
export PATH="${path[*]}"

# Pyenv additions
export PYENV_ROOT="$HOME/.pyenv"
path=("$PYENV_ROOT/bin" $path)
export PATH="${path[*]}"
eval "$(pyenv init --path)"
eval "$(pyenv init -)"

###############################
# Language-Specific Settings
###############################
MANPATH=$(manpath | tr ':' '\n' \
          | grep -v '/Library/TeX/texbin/man' \
          | paste -sd: -)
export MANPATH

###############################
# Golang configuration
###############################
export GOROOT=/usr/local/go
export GOPATH=$HOME/go
path+=($GOPATH/bin $GOROOT/bin)
export PATH="${path[*]}"

###############################
# Mono framework
###############################
export MONO_GAC_PREFIX="/usr/local"

###############################
# Bun JavaScript runtime
###############################
export BUN_INSTALL="$HOME/.bun"
path+=($BUN_INSTALL/bin)
export PATH="${path[*]}"

###############################
# History Configuration
###############################
HISTFILE=~/.zsh/history
HISTSIZE=10000000
SAVEHIST=10000000
HISTORY_IGNORE="(pwd|exit)*"
HIST_STAMPS="yyyy-mm-dd"
setopt APPEND_HISTORY
setopt EXTENDED_HISTORY
setopt SHARE_HISTORY
setopt HIST_IGNORE_ALL_DUPS
setopt HIST_IGNORE_DUPS
setopt HIST_IGNORE_SPACE
setopt HIST_SAVE_NO_DUPS
setopt HIST_FIND_NO_DUPS
setopt HIST_REDUCE_BLANKS
setopt HIST_VERIFY
setopt INC_APPEND_HISTORY
setopt NO_HIST_BEEP

###############################
# Plugin Management
###############################
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
    source "$plugin_dir/${1:t}.plugin.zsh" 2>/dev/null \
      || source "$plugin_dir/${1:t}.zsh" 2>/dev/null \
      || source "$plugin_dir/${1:t}.sh" 2>/dev/null
}
[ -f "$HOME/.local/share/zap/zap.zsh" ] && source "$HOME/.local/share/zap/zap.zsh"
echo 'export PYENV_ROOT="$HOME/.pyenv"'
echo 'command -v pyenv >/dev/null || export PATH="$PYENV_ROOT/bin:$PATH"'
echo 'eval "$(pyenv init -)"'

plug "zsh-users/zsh-autosuggestions"
plug "zdharma-continuum/fast-syntax-highlighting"
plug "zsh-users/zsh-history-substring-search"
plug "MichaelAquilina/zsh-you-should-use"
plug "MichaelAquilina/zsh-autoswitch-virtualenv"

source ~/dotfiles/completions.zsh
autoload -Uz compinit
if [ "$(date +'%j')" != "$(stat -f '%Sm' -t '%j' ~/.zcompdump)" ]; then
  compinit
else
  compinit -C
fi
zstyle ':completion:*' menu select
zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}'
zstyle ':completion:*' list-colors "${(s.:.)LS_COLORS}"
zstyle ':completion:*' verbose yes
zstyle ':completion:*:descriptions' format '%B%d%b'
zstyle ':completion:*:messages' format '%d'
zstyle ':completion:*:warnings' format 'No matches for: %d'
zstyle ':completion:*:corrections' format '%B%d (errors: %e)%b'
unset ZSH
unset ZSH_THEME

###############################
# Source Configurations
###############################
source ~/secrets.sh

DOTFILES_LOADED=0
load_dotfiles() {
    source ~/dotfiles/.zsh.aliases
    source ~/dotfiles/.zsh.functions
    DOTFILES_LOADED=1
}
load_dotfiles
{ sleep 0.1; load_dotfiles; } &!
for cmd in g d k; do
    eval "function $cmd() { [[ \$DOTFILES_LOADED -eq 0 ]] && load_dotfiles; command \$cmd \$@ }"
done

###############################
# Key Bindings
###############################
bindkey '^[[A' history-substring-search-up
bindkey '^[[B' history-substring-search-down
bindkey "^[f" forward-word
bindkey "^[b" backward-word
bindkey "^[[3;5~" kill-word
bindkey '^H' backward-kill-word
bindkey "^[[H" beginning-of-line
bindkey "^[[F" end-of-line

###############################
# Async Load External Tools
###############################
source <(fzf --zsh)
test -e "${HOME}/.iterm2_shell_integration.zsh" && source "${HOME}/.iterm2_shell_integration.zsh"
[ -s "$HOME/.bun/_bun" ] && source "$HOME/.bun/_bun"
[ -f "$HOME/.cargo/env" ] && source "$HOME/.cargo/env"
eval "$(zoxide init zsh)"

###############################
# Performance Improvements
###############################
__git_files() { _wanted files expl 'local files' _files; }
DISABLE_AUTO_UPDATE=true

###############################
# Better Terminal Experience
###############################
HIST_STAMPS="mm/dd/yyyy"
REPORTTIME=10
auto-ls() { ls; }
chpwd_functions=(${chpwd_functions[@]} "auto-ls")
export STARSHIP_CONFIG=~/dotfiles/config/starship/starship.toml
eval "$(starship init zsh)"

###############################
# Vi Mode Configuration
###############################
bindkey -v
export KEYTIMEOUT=1
bindkey -M menuselect 'h' vi-backward-char
bindkey -M menuselect 'k' vi-up-line-or-history
bindkey -M menuselect 'l' vi-forward-char
bindkey -M menuselect 'j' vi-down-line-or-history
zle-keymap-select() {
  if [[ ${KEYMAP} == vicmd ]] || [[ $1 == 'block' ]]; then
    echo -ne '\e[1 q'
  else
    echo -ne '\e[5 q'
  fi
}
zle -N zle-keymap-select
echo -ne '\e[5 q'
precmd() { echo -ne '\e[5 q'; }
preexec() { echo -ne '\e[5 q'; }

eval $(thefuck --alias)
