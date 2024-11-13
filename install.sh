#!/bin/bash

# Install zap plugin manager
zsh <(curl -s https://raw.githubusercontent.com/zap-zsh/zap/master/install.sh) --branch release-v1

# Install core plugins
git clone https://github.com/zsh-users/zsh-autosuggestions ~/.local/share/zsh/plugins/zsh-autosuggestions
git clone https://github.com/zdharma-continuum/fast-syntax-highlighting ~/.local/share/zsh/plugins/fast-syntax-highlighting
git clone https://github.com/zsh-users/zsh-history-substring-search ~/.local/share/zsh/plugins/zsh-history-substring-search 