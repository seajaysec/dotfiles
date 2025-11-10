Kali Linux dotfiles
===================

This directory contains a Linux-adapted version of your macOS shell/tmux setup. It keeps your layout and conventions but adjusts for Debian/Kali specifics (packages, paths, clipboard, bat/batcat, etc.).

What’s included
---------------
- .zshrc (Kali-specific): 
  - Linux paths and environment
  - Starship prompt, with Powerlevel10k fallback
  - Clipboard wrappers (pbcopy/pbpaste on X11/Wayland)
  - bat/batcat handling
  - Auto-start tmux, attaching to the most recent session; works with tmux-resurrect/continuum to restore.
- .zsh.aliases (Kali-specific):
  - eza/exa fallback
  - brew → apt updates for bubu/bcbc-class tasks
  - mac-only aliases guarded or replaced (btfix/audiofix)
- .zsh.functions (Kali-specific):
  - Linux-friendly versions of impaste/remove_dups/bcbc
  - Clipboard-aware helpers using xclip/xsel/wl-copy if present
- .tmux.conf.local (copied from your mac setup, still uses TPM + continuum + resurrect)
- install.sh: One-shot installer to provision dependencies, fonts, starship, tmux (oh-my-tmux + TPM), pyenv deps, create symlinks, and set zsh as default shell.

Quick start
-----------
1) On Kali (VM in VMware on Apple Silicon), clone or sync your dotfiles repo to ~/dotfiles.
2) Run:

   bash ~/dotfiles/Kali/install.sh

3) Start a new terminal. tmux should auto-start and restore your last session when available.

Notes
-----
- Starship is the default prompt (like your mac). If starship isn’t installed, Powerlevel10k is used if present (~/.p10k.zsh).
- Clipboard commands: pbcopy/pbpaste map to wl-copy/wl-paste or xclip/xsel when on Linux.
- bat is aliased to batcat when only batcat is available.
- Tmux: Continuum is configured to auto-restore. Auto-start logic attaches to the most recently attached session if one exists, otherwise creates a new one.


