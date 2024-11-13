#!/bin/bash

# Install zap plugin manager
mkdir -p "$HOME/.local/share/zap"
git clone https://github.com/zap-zsh/zap.git "$HOME/.local/share/zap"

# Create plugins directory
mkdir -p ~/.local/share/zsh/plugins

# Install core plugins
git clone https://github.com/zsh-users/zsh-autosuggestions ~/.local/share/zsh/plugins/zsh-autosuggestions
git clone https://github.com/zdharma-continuum/fast-syntax-highlighting ~/.local/share/zsh/plugins/fast-syntax-highlighting
git clone https://github.com/zsh-users/zsh-history-substring-search ~/.local/share/zsh/plugins/zsh-history-substring-search 