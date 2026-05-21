## Learned User Preferences

- Default to the simplest path that uses the tool's native capabilities. When the tool supports something natively (e.g., iTerm loading an external prefs folder, or built-in tmux integration), do not invent wrappers, symlinks, or shell shims around it.
- Never break existing terminal functionality. You should verify in a fresh shell that PATH still resolves `mkdir`, `uname`, `date`, `stat`, `fzf`, `zoxide`, and `starship` after any change to `.zshrc`, `.zshenv`, `.zprofile`, or anything else that runs at shell init.
- Always test shell, tmux, iTerm, or editor changes in a clean window or process before reporting success. Do not claim work is done from inspecting the diff alone.
- When you are unsure how a tool works, fetch authoritative docs, blog posts, or upstream READMEs instead of improvising. If your current interpretation of the docs is producing weird behavior, stop and re-read primary sources before another attempt.
- When an approach keeps failing, stop and redesign at a higher level instead of doubling down. The user prefers "back to the drawing board" over more patches on a bad foundation.
- Re-read the user's stated constraints before acting and do not undo decisions already made. If the user says something is wrong twice, change direction; do not paraphrase the same approach.
- For editor/IDE-like UIs (e.g., nvim file browser), target a macOS Finder "As Columns" feel: `l` drills into a directory or opens a file, `h` goes up a level, the current view is replaced rather than expanded inline as a tree.
- Match the user's Dracula Pro iTerm color scheme; avoid clashing default colorschemes in new tools.
- Treat the public remote as the source of truth that follows the user across machines. Push non-secret changes there and keep the installer able to bootstrap a new device from a clean clone.
- Prefer the modern CLI tools already installed: `eza` (not `ls`), `rg` (not `grep`), `fd` (not `find`), `bat`, `fzf`, `zoxide`, `starship`, `delta`, `tldr`.

## Learned Workspace Facts

- The canonical repo lives at `~/dotfiles`. `~/.zshrc`, `~/.zshenv`, and `~/.zprofile` are symlinks into this repo created by `./install.sh`. Edit the repo copies, never the home copies.
- Secrets stay out of the repo. Put them in `~/secrets.sh` (sourced from `.zshrc`) or `~/.zshrc.local`; never write tokens, credentials, internal hostnames, or work-only paths into tracked files.
- iTerm uses tmux `-CC` control mode as its window/pane substrate. The default Dynamic Profile runs `tmux -CC new-session -A -s <session>`. `⌘T` = new tmux window, `⌘D` / `⇧⌘D` = splits, `⌘O → Plain` for a non-tmux shell.
- `⌘Q` detaches iTerm and keeps every tmux process running. `⌘W` (closing a window) KILLS those processes. Always detach to preserve work; never instruct the user to "close" the window to save state.
- The tmux session name is controlled by `config/iterm2/session-name` (one line, default `main`). After changing it, run `./config/iterm2/render-tmux-profile.sh` then `./install.sh --link-only`. The shell `tm` alias reads the same name via `tmux_session` in `.zshenv`.
- iTerm Dynamic Profiles live under `config/iterm2/DynamicProfiles/` and are loaded by pointing iTerm at the custom prefs folder. Do not symlink prefs plists when the prefs-folder mechanism already covers it.
- Apple Silicon `tmux` path is `/opt/homebrew/bin/tmux` and is hardcoded in the Dynamic Profile. Intel Macs are not supported in-repo (callers must set `TMUX_BIN` when rendering).
- Shell stack: `zap` plugin manager, `starship` prompt, `zsh-autoswitch-virtualenv` for Python venvs at `~/.virtualenvs/{dirname}-{xxxx}`. When a project has no matching venv, fall back to the Homebrew/system Python instead of erroring at launch.
- `cd` is aliased to `zoxide` (`z`) for interactive use, but every function and alias in `.zsh.aliases` / `.zsh.functions` must invoke the real `cd` to stay safe under that aliasing.
- VS Code and Cursor `settings.json` are symlinked out of this repo so changes follow the user across machines. The installer must (re)create those symlinks on new devices.
- The key files for any shell behavior work are `.zshrc`, `.zshenv`, `.zsh.aliases`, `.zsh.functions`, `install.sh`, and the `config/iterm2/` tree. Read all of them before refactoring shell init.
- GSD (get-shit-done) workflow scaffolding lives at `~/.cursor/get-shit-done/` and `~/.cursor/skills/`. Slash commands like `/gsd-plan-phase`, `/gsd-execute-phase`, and `/gsd-verify-work` drive multi-phase work and write artifacts under `.planning/` in the current repo.
