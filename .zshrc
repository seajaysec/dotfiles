###############################
# Core Environment Variables
###############################
# If the parent process left PATH empty or unusable (Cursor, GUI tools, `env -i`),
# bootstrap standard system locations before any command substitution or plugins run.
if ! command -v mkdir >/dev/null 2>&1; then
  export PATH="/usr/bin:/bin:/usr/sbin:/sbin:/opt/homebrew/bin:/usr/local/bin${PATH:+:$PATH}"
fi

setopt extended_glob
# DOTFILES: prefer env / zshenv; else ~/dotfiles; else directory of this file (works when repo is not under ~/dotfiles).
: "${DOTFILES:=$HOME/dotfiles}"
[[ -r "${DOTFILES}/.zsh.aliases" ]] || DOTFILES="${${(%):-%x}:A:h}"
autoload -Uz add-zsh-hook
export TERM=xterm-256color
export LANG=en_US.UTF-8
# Apple Silicon vs Intel (FIX-01 / Phase 4)
if [[ $(uname -m) == arm64 ]]; then
  export ARCHFLAGS="-arch arm64"
else
  export ARCHFLAGS="-arch x86_64"
fi
export GROFF_NO_SGR=1
export EDITOR=vim
export VISUAL=vim
export ACK_PAGER_COLOR="{$PAGER:-bat --style=plain --paging=always}"
export PAGER='bat --style=plain --paging=always'
export MANPAGER="sh -c 'col -bx | bat --style=plain -l man --paging=always'"
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
_pyenv_root="$(brew --prefix pyenv 2>/dev/null)" && [[ -f "$_pyenv_root/completions/pyenv.zsh" ]] && source "$_pyenv_root/completions/pyenv.zsh"
unset _pyenv_root
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

# menuselect keymap (needed before `bindkey -M menuselect` in Vi Mode) — was in completions.zsh
zmodload zsh/complist

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

###############################
# Source Configurations
###############################
source ~/secrets.sh

source "${DOTFILES}/.zsh.aliases"
source "${DOTFILES}/.zsh.functions"

###############################
# Vi + keymaps (KEYS-* — Phase 3: bindkey -v before other bindkeys; emacs keys on viins)
###############################
bindkey -v
export KEYTIMEOUT=10
bindkey -M viins '^A' beginning-of-line
bindkey -M viins '^E' end-of-line
bindkey -M viins '^[[A' history-substring-search-up
bindkey -M viins '^[[B' history-substring-search-down
bindkey -M viins '^[f' forward-word
bindkey -M viins '^[b' backward-word
bindkey -M viins '^[[3;5~' kill-word
bindkey -M viins '^H' backward-kill-word
bindkey -M viins '^[[H' beginning-of-line
bindkey -M viins '^[[F' end-of-line
bindkey -M menuselect 'h' vi-backward-char
bindkey -M menuselect 'k' vi-up-line-or-history
bindkey -M menuselect 'l' vi-forward-char
bindkey -M menuselect 'j' vi-down-line-or-history

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
# Better Terminal Experience
###############################
REPORTTIME=10
auto-ls() { ls; }
add-zsh-hook chpwd auto-ls

export CHECK_ROOT="/Users/chris.j.farrell/gits/check"
export CHECK_PYTHON="/Users/chris.j.farrell/.virtualenvs/check-wivc/bin/python3"
if [ -f "$CHECK_ROOT/check_function.zsh" ]; then
  source "$CHECK_ROOT/check_function.zsh"
fi

# Starship last among interactive tool evals (ARCH-06 / 02-03)
export STARSHIP_CONFIG="${DOTFILES}/config/starship/starship.toml"
eval "$(starship init zsh)"

# Vi cursor shape after Starship init so we don't clobber Starship's zle / precmd registration (HOOK-* / Phase 3)
zle-keymap-select() {
  if [[ ${KEYMAP} == vicmd ]] || [[ $1 == 'block' ]]; then
    echo -ne '\e[1 q'
  else
    echo -ne '\e[5 q'
  fi
}
zle -N zle-keymap-select
# HOOK-03 risk: we redefine `zle-keymap-select` after Starship; if prompt glitches on keymap change,
# compare with Starship zsh docs / version — may need to chain the previous widget instead of replacing.

add-zsh-hook precmd _dotfiles_cursor_precmd
_dotfiles_cursor_precmd() { echo -ne '\e[5 q'; }
add-zsh-hook preexec _dotfiles_cursor_preexec
_dotfiles_cursor_preexec() { echo -ne '\e[5 q'; }

# PERF-05: collapse duplicate PATH segments after integrations (preserve order)
typeset -U _dedupe_path_segments
_dedupe_path_segments=(${(s.:.)PATH})
export PATH=${(j.:.)_dedupe_path_segments}

# Machine-specific overrides (ARCH-07 / 02-03); migrate secrets from ~/secrets.sh over time
[[ -f "$HOME/.zshrc.local" ]] && source "$HOME/.zshrc.local"