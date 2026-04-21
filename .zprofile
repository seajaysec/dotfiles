# Login PATH — Homebrew + system + user bins (ARCH-02). Interactive-only: ~/.zshrc
typeset -U path
if [[ -x /opt/homebrew/bin/brew ]]; then
  eval "$(/opt/homebrew/bin/brew shellenv)"
elif [[ -x /usr/local/bin/brew ]]; then
  eval "$(/usr/local/bin/brew shellenv)"
fi
path=(
  /opt/homebrew/bin
  /opt/homebrew/opt/openssl@3/bin
  /usr/local/bin
  /usr/local/sbin
  /usr/bin
  /usr/sbin
  /bin
  /sbin
  "$HOME/.local/bin"
  "$HOME/.npm-packages/bin"
  "$HOME/.npm-packages/lib/node_modules/n/bin"
  /bin/lscript
  "$HOME/.cargo/bin"
)
export PATH="${(j.:.)path}"
