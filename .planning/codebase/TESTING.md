# Testing

> Last mapped: 2026-04-21

## Testing Approach

This dotfiles repository has **no automated test suite**. There are no unit tests, integration tests, or CI pipelines. Validation is entirely manual and relies on:

1. **Interactive usage** — configs are validated by daily use after sourcing
2. **Visual confirmation** — `install.sh` and `brewup.sh` print colored status messages so the user can visually verify each step completed
3. **Fail-fast scripting** — `install.sh` uses `set -e` so any command failure halts the entire script, serving as a crude runtime assertion

This is typical for dotfiles repositories where the "test" is whether the shell starts correctly and tools work as expected.

## Validation Patterns

### Command-Exists Checks

`install.sh` gates installation steps on whether a tool is already present:

```bash
# Git / Xcode CLI tools
if ! command -v git >/dev/null 2>&1; then
    xcode-select --install
    until command -v git >/dev/null 2>&1; do sleep 5; done
fi

# Homebrew
if ! command -v brew >/dev/null 2>&1; then
    /bin/bash -c "$(curl -fsSL ...)"
fi

# Zsh
if ! command -v zsh >/dev/null 2>&1; then
    brew install zsh
fi
```

`brewup.sh` checks for required tools and auto-installs them:

```bash
if [ -z $(which mas) ]; then
    brew install mas 2>/dev/null
fi

if [ -z $(which realpath) ]; then
    brew install coreutils
fi
```

`.zsh.functions` checks for tool availability before use:

```bash
# In fatsort_volume()
if ! fatsort_path=$(command -v fatsort); then
    echo "Error: fatsort command not found."
    return 1
fi
```

### Architecture Detection

`brewup.sh` detects ARM64 (Apple Silicon) to fix Homebrew's PATH:

```bash
if [ $(arch) = "arm64" ]; then
    export PATH="/opt/homebrew/bin:/opt/homebrew/sbin:$PATH"
fi
```

`install.sh` handles both Homebrew install locations:

```bash
eval "$(/opt/homebrew/bin/brew shellenv)" 2>/dev/null || eval "$(/usr/local/bin/brew shellenv)"
```

### Shell Detection

`.zshrc` checks if the default shell is already zsh:

```bash
if [[ $SHELL != *"zsh"* ]]; then
    chsh -s "$BREW_ZSH"
fi
```

### Conditional Sourcing

`.zshrc` guards external tool loading with file/command existence checks:

```bash
[ -f "$HOME/.local/share/zap/zap.zsh" ] && source "$HOME/.local/share/zap/zap.zsh"
test -e "${HOME}/.iterm2_shell_integration.zsh" && source "${HOME}/.iterm2_shell_integration.zsh"
[ -s "$HOME/.bun/_bun" ] && source "$HOME/.bun/_bun"
[ -f "$HOME/.cargo/env" ] && source "$HOME/.cargo/env"
[[ -f /opt/homebrew/opt/pyenv/completions/pyenv.zsh ]] && source ...
```

This ensures `.zshrc` never fails on a machine missing optional tools.

### Completion Cache Optimization

`.zshrc` validates the compinit dump file's freshness by day-of-year to avoid expensive regeneration:

```bash
if [ "$(date +'%j')" != "$(stat -f '%Sm' -t '%j' ~/.zcompdump)" ]; then
    compinit
else
    compinit -C
fi
```

### Network Availability Checks

Functions in `.zsh.functions` validate network state before operations:

```bash
# dualping() checks VPN interface
if ifconfig utun8 2>/dev/null | grep -q "inet "; then
    # VPN path
else
    # Non-VPN path
fi
```

### Input Validation in Functions

Functions consistently validate inputs before acting:

- **File existence**: `if [[ ! -f "$input" ]]; then echo "Error: File not found"; return 1; fi` (`m2d`)
- **Argument presence**: `if [ -z "$1" ]; then echo "Usage: ..."; return 1; fi` (most functions)
- **Volume/device checks**: `if [ -z "$device_node" ]; then echo "Error: Volume not found"; return 1; fi` (`fatsort_volume`)
- **Branch safety**: `if [[ "$branch" == "main" ]]; then echo "Already on main"; return 1; fi` (`finish-branch`)

## Install Verification

### `install.sh` Verification Strategy

`install.sh` provides **minimal automated verification**:

1. **`set -e`** — any command failure stops the script immediately, so reaching the end implies success
2. **`command -v` polling** — after triggering Xcode CLI tools install, it polls until `git` is available:
   ```bash
   until command -v git >/dev/null 2>&1; do sleep 5; done
   ```
3. **Shell registration check** — verifies Homebrew's zsh is in `/etc/shells` before setting it as default:
   ```bash
   if ! grep -q "$BREW_ZSH" /etc/shells; then
       echo "$BREW_ZSH" | sudo tee -a /etc/shells
   fi
   ```
4. **Success message** — prints `✨ Installation complete!` at the end with next-step instructions

### What Is NOT Verified

- No check that sourcing `.zshrc` succeeds after install
- No check that all brew packages installed correctly (relies on `set -e`)
- No check that plugin managers (zap) initialized properly
- No check that config file copies landed correctly
- No check that secrets.sh was populated with needed values
- No smoke test of aliases or functions

### `brewup.sh` Verification

`brewup.sh` provides **no explicit verification**. It:
1. Runs `brew update`, `brew upgrade`, `brew cleanup` sequentially
2. Dumps the Brewfile
3. Commits and pushes to git
4. Prints a colored "Finished" message

The git commit serves as an implicit checkpoint — the Brewfile diff shows what changed.

## Rollback Strategy

### Git-Based Rollback

The primary rollback mechanism is **git history**. All config files are tracked, so:

```bash
git diff HEAD~1           # See what changed
git checkout HEAD~1 -- .zshrc  # Revert a specific file
git reset --hard HEAD~1   # Full rollback
```

`brewup.sh` auto-commits on every run with timestamped messages (`20260421.1430_update`), creating natural restore points.

### Brewfile Snapshots

Each `brewup.sh` run dumps the current Homebrew state to `Brewfile.${HOSTNAME}`. To restore packages to a prior state:

```bash
git checkout <commit> -- Brewfile.${HOSTNAME}
brew bundle --file=Brewfile.${HOSTNAME}
```

### No Backup-Before-Write

`install.sh` **does not back up existing configs** before overwriting:

```bash
cp .zshrc ~/.zshrc           # Overwrites without backup
cp .zsh.functions ~/dotfiles/
cp .zsh.aliases ~/dotfiles/
```

If the user has local modifications to `~/.zshrc` that aren't committed, they will be lost.

### Tmux Config Safety

The tmux setup has a built-in safety valve: `.tmux.conf` sources `.tmux.conf.local` with `source -q` (quiet mode), so a broken local config won't prevent tmux from starting:

```
source -q ~/.tmux.conf.local
```

### Secrets Isolation

`~/secrets.sh` is created with `touch` (won't overwrite existing) and is never committed to git, so secret values survive reinstalls:

```bash
touch ~/secrets.sh    # No-op if exists
```

### Manual Rollback Steps

To fully roll back to a clean state:
1. `git log` to find the desired commit
2. `git checkout <commit> -- <file>` for individual files
3. `source ~/.zshrc` to reload
4. For Homebrew: restore the Brewfile and run `brew bundle cleanup --force`
5. For tmux: `tmux source ~/.tmux.conf` to reload
