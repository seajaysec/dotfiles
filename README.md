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

### Terminal Customization

#### Nerd Fonts
Install a patched Nerd Font for proper icon support:

1. Download Hack Nerd Font from [Nerd Fonts](https://www.nerdfonts.com/font-downloads):
```bash
brew tap homebrew/cask-fonts
brew install --cask font-hack-nerd-font
```

2. Configure iTerm2:
- Open iTerm2 Preferences (⌘,)
- Go to Profiles > Text
- Select "Hack Nerd Font" or "Hack Nerd Font Mono" in both Font fields

#### Color Scheme
This configuration has been tested with the Dracula theme:

1. Download the iTerm2 Dracula theme:
```bash
curl -O https://raw.githubusercontent.com/dracula/iterm/master/Dracula.itermcolors
```

2. Import the theme:
- Open iTerm2 Preferences
- Go to Profiles > Colors
- Click "Color Presets..." dropdown
- Select "Import..."
- Choose the downloaded Dracula.itermcolors file
- Select "Dracula" from Color Presets

Note: The configuration has been tested with Hack Nerd Font and Dracula theme, but you can use any Nerd Font and color scheme of your choice.

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
