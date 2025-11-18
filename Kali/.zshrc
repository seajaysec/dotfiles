###############################
# Kali Linux zsh configuration
###############################
setopt extended_glob

###############################
# Core Environment Variables
###############################
export LANG=en_US.UTF-8
export GROFF_NO_SGR=1
export EDITOR=vim
export VISUAL=vim

# Prefer bat; on Debian-based systems the binary may be batcat
if command -v bat >/dev/null 2>&1; then
  export ACK_PAGER_COLOR="{$PAGER:-bat --style=plain --paging=always}"
  export PAGER='bat --style=plain --paging=always'
  export MANPAGER="sh -c 'col -bx | bat --style=plain -l man --paging=always'"
elif command -v batcat >/dev/null 2>&1; then
  alias bat='batcat'
  export ACK_PAGER_COLOR="{$PAGER:-batcat --style=plain --paging=always}"
  export PAGER='batcat --style=plain --paging=always'
  export MANPAGER="sh -c 'col -bx | batcat --style=plain -l man --paging=always'"
else
  export PAGER='less -R'
fi

###############################
# Path Configuration
###############################
typeset -U path
path=(
  /usr/local/bin
  /usr/local/sbin
  /usr/bin
  /usr/sbin
  /bin
  /sbin
  ~/.local/bin
  ~/.cargo/bin
)
export PATH

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
# Clipboard shims (Linux)
###############################
if [[ "$OSTYPE" != darwin* ]]; then
  if command -v wl-copy >/dev/null 2>&1; then
    alias pbcopy='wl-copy'
    alias pbpaste='wl-paste -n'
  elif command -v xclip >/dev/null 2>&1; then
    alias pbcopy='xclip -selection clipboard'
    alias pbpaste='xclip -selection clipboard -o'
  elif command -v xsel >/dev/null 2>&1; then
    alias pbcopy='xsel --clipboard --input'
    alias pbpaste='xsel --clipboard --output'
  fi
fi

###############################
# Pyenv
###############################
export PYENV_ROOT="$HOME/.pyenv"
if [ -d "$PYENV_ROOT" ]; then
  path=("$PYENV_ROOT/bin" $path)
  export PATH
  eval "$(pyenv init --path)" 2>/dev/null
  eval "$(pyenv init -)" 2>/dev/null
fi


###############################
# Plugin Management (zap)
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

plug "zsh-users/zsh-autosuggestions"
plug "zdharma-continuum/fast-syntax-highlighting"
plug "zsh-users/zsh-history-substring-search"
plug "MichaelAquilina/zsh-you-should-use"
plug "MichaelAquilina/zsh-autoswitch-virtualenv"

###############################
# Completions
###############################
source ~/dotfiles/completions.zsh 2>/dev/null
autoload -Uz compinit
if [ -f ~/.zcompdump ]; then compinit -C; else compinit; fi
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
[ -f ~/secrets.sh ] && source ~/secrets.sh

DOTFILES_LOADED=0
load_dotfiles() {
  source ~/dotfiles/Kali/.zsh.aliases
  source ~/dotfiles/Kali/.zsh.functions
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
# Load fzf integration if the actual binary exists (ignore aliases/functions)
(( $+commands[fzf] )) && source <(${commands[fzf]} --zsh)
[ -s "$HOME/.bun/_bun" ] && source "$HOME/.bun/_bun"
[ -f "$HOME/.cargo/env" ] && source "$HOME/.cargo/env"
command -v zoxide >/dev/null 2>&1 && eval "$(zoxide init zsh)"

###############################
# PATH failsafe (recover from accidental space-joined PATH)
###############################
if [[ "$PATH" == *" "* ]]; then
  export PATH="/usr/local/bin:/usr/local/sbin:/usr/bin:/usr/sbin:/bin:/sbin:$HOME/.local/bin:$HOME/.cargo/bin"
fi

###############################
# Better Terminal Experience
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
REPORTTIME=10
auto-ls() { ls; }
chpwd_functions=(${chpwd_functions[@]} "auto-ls")

###############################
# Prompt (Starship, fallback P10K)
###############################
export STARSHIP_CONFIG=~/dotfiles/config/starship/starship.toml
if command -v starship >/dev/null 2>&1; then
  eval "$(starship init zsh)"
elif [ -f ~/.p10k.zsh ]; then
  source ~/.p10k.zsh
fi

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

# The Fuck
command -v thefuck >/dev/null 2>&1 && eval "$(thefuck --alias)"

###############################
# Auto-start tmux and restore latest session
###############################
if [[ $- == *i* ]] && command -v tmux >/dev/null 2>&1; then
  if [[ -z "$TMUX" && "$TERM" != screen* && -z "${VSCODE_INJECTION:-}" && -z "${TERMINAL_EMULATOR:-}" ]]; then
    last_session=$(tmux ls -F "#{?session_attached,999999999,#{session_last_attached}} #{session_name}" 2>/dev/null | sort -nr | awk 'NR==1{print $2}')
    if [[ -n "$last_session" ]]; then
      exec tmux attach -t "$last_session"
    else
      exec tmux new -s work
    fi
  fi
fi