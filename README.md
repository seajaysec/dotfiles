# Dotfiles

A collection of shell configuration files and utilities for macOS development environment.

## Prerequisites

### Command Line Tools
Install Xcode Command Line Tools:
`xcode-select --install`

### Homebrew
Install Homebrew package manager:
`/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"`

## Core Installation

### Essential Packages
Install core utilities via Homebrew:

```bash
brew install \
    eza                  # Modern ls replacement \
    ripgrep              # Modern grep replacement (rg command) \
    fzf                  # Fuzzy finder \
    tmux                 # Terminal multiplexer \
    grc                  # Generic colourizer \
    blueutil             # Bluetooth control utility \
    gsed                 # GNU sed \
    rlwrap               # Readline wrapper \
    fd                   # Modern find replacement \
    bat                  # Modern cat replacement \
    delta                # Better git diff \
    tldr                 # Simplified man pages \
    the_silver_searcher  # Fast code searching \
    highlight            # Source code highlighter \
    zoxide               # Smarter cd command \
    nmap                 # Network scanning \
    ffmpeg               # Media conversion \
    imagemagick          # Image processing \
    openssl              # SSL/TLS toolkit \
    python               # Python interpreter \
    ipython              # Enhanced Python REPL \
    starship             # Cross-shell prompt
```

### Shell Setup

1. Run the installation script:
```bash
./install.sh
```

This will set up:
- Zap plugin manager
- Core zsh plugins:
  - Fast Syntax Highlighting
  - Autosuggestions
  - History Substring Search
  - You Should Use (alias reminder)

2. Copy configuration files:
```bash
mkdir -p ~/dotfiles/config/starship
cp .zshrc ~/.zshrc
cp completions.zsh ~/dotfiles/
cp config/starship/starship.toml ~/dotfiles/config/starship/
```

### Development Tools

Node Version Manager (nvm):
`curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.0/install.sh | bash`

Bun JavaScript Runtime:
`curl -fsSL https://bun.sh/install | bash`

Rust and Cargo:
`curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh`

Python Packages:
`pip3 install virtualenv ipython`

### Optional but Recommended

iTerm2 Terminal Emulator:
`brew install --cask iterm2`

Anaconda Python Distribution:
`brew install --cask anaconda`

## Post-Installation Setup

### Directory Structure

Set up required directories:
```bash
sudo mkdir -p /opt/gists
sudo chown $USER:staff /opt/gists
mkdir -p ~/dotfiles/config/starship
```

### Environment Configuration

1. Copy dotfiles to home directory:
- .zshrc → ~/.zshrc
- .zsh.functions → ~/dotfiles/.zsh.functions
- .zsh.aliases → ~/dotfiles/.zsh.aliases
- config/starship/starship.toml → ~/dotfiles/config/starship/starship.toml

2. Create secrets file:
`touch ~/secrets.sh`

3. Configure fzf:
`$(brew --prefix)/opt/fzf/install`

### Final Steps

1. Restart your terminal or source the new configuration:
`source ~/.zshrc`

## Features

- Fast, modern shell setup with minimal dependencies
- Starship prompt for beautiful, informative terminal prompt
- Smart command history with substring search
- Syntax highlighting and autosuggestions
- Advanced tab completions
- Git integration
- Docker and Kubernetes aliases
- Efficient directory navigation with zoxide
- Modern CLI tools (ripgrep, fd, bat, etc.)

## Usage Notes

- Some functions require specific permissions (e.g., pskill needs sudo access)
- Network scanning functions may require root privileges
- Set `HOMEBREW_NO_AUTO_UPDATE=1` to speed up brew operations (optional)
- Ensure PATH includes /usr/local/bin and /opt/homebrew/bin

## Maintenance

- Update Homebrew packages: `brew update && brew upgrade`
- Update plugins: `cd ~/.local/share/zsh/plugins/* && git pull`
- Update tldr pages: `tldr --update`
- Update Starship: `brew upgrade starship`

## Performance

This configuration prioritizes performance while maintaining functionality:
- Fast startup time through efficient plugin management
- Lazy loading for heavy tools
- Optimized completion system
- Minimal dependencies
