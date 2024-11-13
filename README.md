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
  - Fast Syntax Highlighting - Real-time syntax highlighting for enhanced readability and error detection
  - Autosuggestions - Fish-like suggestions based on command history
  - History Substring Search - Type part of a command and use up/down arrows to search
  - You Should Use - Gentle reminders about available aliases
  - Autoswitch Virtualenv - Automatically activates/deactivates Python virtual environments as you navigate directories

### Vi Mode Features

This configuration includes a powerful Vi mode setup that transforms your shell into a Vi-like environment:

#### Mode Indicators
The cursor shape changes to indicate your current mode:
- Normal Mode: Blinking block cursor
- Insert Mode: Blinking beam cursor (like a standard terminal)

#### Common Vi Navigation Shortcuts
Normal Mode (press ESC to enter):
- `h`, `j`, `k`, `l` - Left, down, up, right
- `w` - Jump to next word
- `b` - Jump to previous word
- `0` - Jump to start of line
- `$` - Jump to end of line
- `f{char}` - Jump to next occurrence of {char}
- `F{char}` - Jump to previous occurrence of {char}
- `gg` - Jump to beginning of history
- `G` - Jump to end of history

#### Text Manipulation
- `dd` - Delete current line
- `dw` - Delete word
- `d$` - Delete to end of line
- `cc` - Change entire line
- `cw` - Change word
- `ci"` - Change inside quotes
- `yy` - Yank (copy) line
- `p` - Paste after cursor
- `P` - Paste before cursor

#### Search and History
- `/` - Search forward
- `?` - Search backward
- `n` - Next search result
- `N` - Previous search result
- `ctrl-p` - Previous command (while in insert mode)
- `ctrl-n` - Next command (while in insert mode)

#### Menu Navigation
When in completion menus:
- `h`, `j`, `k`, `l` - Navigate completion options
- `Enter` - Select completion
- `Esc` - Exit completion menu

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

- Vi mode with visual mode indicators and enhanced navigation
- Fast, modern shell setup with minimal dependencies
- Starship prompt for beautiful, informative terminal prompt
- Smart command history with substring search
- Syntax highlighting and autosuggestions
- Advanced tab completions
- Automatic Python virtualenv switching
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
