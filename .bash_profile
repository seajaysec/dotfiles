# ~/.bash_profile — login bash (Terminal, `bash -l`, Codex, GUI env resolution).
# Bash reads only this on login, so hand off to .bashrc (which loads .profile).
[ -r "$HOME/.bashrc" ] && . "$HOME/.bashrc"
