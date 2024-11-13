# Dotfiles

A collection of shell configuration files and utilities for macOS development environment.

## Prerequisites

### Command Line Tools
Install Xcode Command Line Tools:
xcode-select --install

### Homebrew
Install Homebrew package manager:
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

## Core Installation

### Essential Packages
Install core utilities via Homebrew:

brew install \
    eza                  # Modern ls replacement \
    ripgrep              # Modern grep replacement (rg command) \
    fzf                  # Fuzzy finder \
    tmux                 # Terminal multiplexer \
    grc                  # Generic colourizer \
    blueutil             # Bluetooth control utility \
    gsed                 # GNU sed \
    rlwrap              # Readline wrapper \
    fd                   # Modern find replacement \
    bat                  # Modern cat replacement \
    delta                # Better git diff \
    tldr                 # Simplified man pages \
    the_silver_searcher  # Fast code searching \
    highlight            # Source code highlighter \
    zoxide              # Smarter cd command \
    nmap                # Network scanning \
    ffmpeg              # Media conversion \
    imagemagick         # Image processing \
    openssl             # SSL/TLS toolkit \
    python              # Python interpreter \
    ipython             # Enhanced Python REPL

### Shell Setup

1. Install Oh My Zsh:
sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"

2. Install Powerlevel10k theme:
git clone --depth=1 https://github.com/romkatv/powerlevel10k.git ${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/themes/powerlevel10k

3. Install required Oh My Zsh plugins:

Fast Syntax Highlighting:
git clone https://github.com/zdharma-continuum/fast-syntax-highlighting.git ${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/F-Sy-H

Autosuggestions:
git clone https://github.com/zsh-users/zsh-autosuggestions ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-autosuggestions

You Should Use:
git clone https://github.com/MichaelAquilina/zsh-you-should-use.git ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/you-should-use

### Development Tools

Node Version Manager (nvm):
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.0/install.sh | bash

Bun JavaScript Runtime:
curl -fsSL https://bun.sh/install | bash

Rust and Cargo:
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh

Python Packages:
pip3 install virtualenv ipython

### Optional but Recommended

iTerm2 Terminal Emulator:
brew install --cask iterm2

Anaconda Python Distribution:
brew install --cask anaconda

## Post-Installation Setup

### Directory Structure

Set up required directories:
sudo mkdir -p /opt/gists
sudo chown $USER:staff /opt/gists

### Environment Configuration

1. Copy dotfiles to home directory:
- .zshrc → ~/.zshrc
- .zsh.functions → ~/dotfiles/.zsh.functions
- .zsh.aliases → ~/dotfiles/.zsh.aliases

2. Create secrets file:
touch ~/secrets.sh

3. Configure fzf:
$(brew --prefix)/opt/fzf/install

### Final Steps

1. Restart your terminal or source the new configuration:
source ~/.zshrc

2. Run p10k configure if you want to customize Powerlevel10k:
p10k configure

## Usage Notes

- Some functions require specific permissions (e.g., pskill needs sudo access)
- Network scanning functions may require root privileges
- Set HOMEBREW_NO_AUTO_UPDATE=1 to speed up brew operations (optional)
- Ensure PATH includes /usr/local/bin and /opt/homebrew/bin

## Maintenance

- Update Homebrew packages: brew update && brew upgrade
- Update Oh My Zsh: omz update
- Update tldr pages: tldr --update

## License

This project is licensed under the MIT License - see the LICENSE file for details.