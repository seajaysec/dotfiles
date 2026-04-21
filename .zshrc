###############################
# Core Environment Variables
###############################
# If the parent process left PATH empty or unusable (Cursor, GUI tools, `env -i`),
# bootstrap standard system locations before any command substitution or plugins run.
if ! command -v mkdir >/dev/null 2>&1; then
  export PATH="/usr/bin:/bin:/usr/sbin:/sbin:/opt/homebrew/bin:/usr/local/bin${PATH:+:$PATH}"
fi

setopt extended_glob
export ZSH=~/.oh-my-zsh
export TERM=xterm-256color
export LANG=en_US.UTF-8
export ARCHFLAGS="-arch x86_64"
export GROFF_NO_SGR=1
export EDITOR=vim
export VISUAL=vim
export ACK_PAGER_COLOR="{$PAGER:-bat --style=plain --paging=always}"
export PAGER='bat --style=plain --paging=always'
export MANPAGER="sh -c 'col -bx | bat --style=plain -l man --paging=always'"
unset LESSOPEN
bindkey "^A" beginning-of-line
bindkey "^E" end-of-line


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
            (bat --style=plain --color=always {} || cat {}) 2>/dev/null | 
            head -300'
  --preview-window='right:hidden:wrap'
  --bind='f3:execute(bat --style=plain {} || bat {})'
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
export PATH="${(j.:.)path}"

# Pyenv additions (optimized - no subshells, no rehash at startup)
export PYENV_ROOT="$HOME/.pyenv"
export PATH="$PYENV_ROOT/shims:$PYENV_ROOT/bin:$PATH"
export PYENV_SHELL=zsh
# Source pyenv completions (use symlinked path, not versioned cellar path)
[[ -f /opt/homebrew/opt/pyenv/completions/pyenv.zsh ]] && source /opt/homebrew/opt/pyenv/completions/pyenv.zsh
pyenv() {
  local command=${1:-}
  [ "$#" -gt 0 ] && shift
  case "$command" in
    activate|deactivate|rehash|shell) eval "$(pyenv "sh-$command" "$@")" ;;
    *) command pyenv "$command" "$@" ;;
  esac
}

###############################
# Golang configuration
###############################
export GOROOT=/usr/local/go
export GOPATH=$HOME/go

###############################
# Mono framework
###############################
export MONO_GAC_PREFIX="/usr/local"

###############################
# Bun JavaScript runtime
###############################
export BUN_INSTALL="$HOME/.bun"
path+=($GOPATH/bin $GOROOT/bin $BUN_INSTALL/bin)
export PATH="${(j.:.)path}"

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
# Plugin Management (via zap)
###############################
[ -f "$HOME/.local/share/zap/zap.zsh" ] && source "$HOME/.local/share/zap/zap.zsh"

# Zap plugins — fast-syntax-highlighting must load last (FIX-08 / 02-03)
plug "zsh-users/zsh-autosuggestions"
plug "zsh-users/zsh-history-substring-search"
plug "MichaelAquilina/zsh-you-should-use"
plug "MichaelAquilina/zsh-autoswitch-virtualenv"
plug "zdharma-continuum/fast-syntax-highlighting"

# Docker completions on fpath before compinit (FIX-09 / 02-03)
DOCKER_COMP="$(brew --prefix docker-completion 2>/dev/null)/share/zsh/site-functions"
if [[ -d "$DOCKER_COMP" ]]; then
  fpath+=("$DOCKER_COMP")
fi

# Completion: merged from former completions.zsh (ARCH-04 / 02-02)
mkdir -p "${HOME}/.cache/zsh"
fpath+=~/.zfunc
_comp_options+=(globdots)
zstyle ':completion::complete:*' use-cache 1
zstyle ':completion::complete:*' cache-path "${HOME}/.cache/zsh"
zstyle ':completion:*:matches' group 'yes'
zstyle ':completion:*:options' description 'yes'
zstyle ':completion:*:options' auto-description '%d'
zstyle ':completion:*:default' list-prompt '%S%M matches%s'
zstyle ':completion:*' group-name ''

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

source ~/dotfiles/.zsh.aliases
source ~/dotfiles/.zsh.functions

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
export ITERM_ENABLE_SHELL_INTEGRATION_WITH_TMUX=YES

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

export CHECK_ROOT="/Users/chris.j.farrell/gits/check"
export CHECK_PYTHON="/Users/chris.j.farrell/.virtualenvs/check-wivc/bin/python3"
if [ -f "$CHECK_ROOT/check_function.zsh" ]; then
  source "$CHECK_ROOT/check_function.zsh"
fi

# Starship last among interactive tool evals (ARCH-06 / 02-03)
export STARSHIP_CONFIG=~/dotfiles/config/starship/starship.toml
eval "$(starship init zsh)"

# PERF-05: collapse duplicate PATH segments after integrations (preserve order)
typeset -U _dedupe_path_segments
_dedupe_path_segments=(${(s.:.)PATH})
export PATH=${(j.:.)_dedupe_path_segments}

# Machine-specific overrides (ARCH-07 / 02-03); migrate secrets from ~/secrets.sh over time
[[ -f "$HOME/.zshrc.local" ]] && source "$HOME/.zshrc.local"