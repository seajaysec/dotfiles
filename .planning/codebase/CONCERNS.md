# Concerns

> Last mapped: 2026-04-21

## Technical Debt

### Duplicate / Conflicting Settings in `.zshrc`

- **`HIST_STAMPS` set twice** with different formats: `"yyyy-mm-dd"` on line 122 and `"mm/dd/yyyy"` on line 204. The second value silently overwrites the first. Only one should remain.
- **`PATH` rebuilt repeatedly** across lines 15, 70, 74, 101, and 113. Each `export PATH="${path[*]}"` re-exports the entire array. The initial `export PATH="/opt/homebrew/bin:$PATH"` on line 15 is redundant since `/opt/homebrew/bin` is already the first entry in the `path` array on line 56.
- **`ARCHFLAGS` conflict**: `.zshrc` line 8 sets `ARCHFLAGS="-arch x86_64"` globally, but this machine is Apple Silicon (arm64). The `ssdeep_env()` function in `.zsh.functions` correctly sets `"-arch arm64"`, implying the global default is wrong.
- **Starship prompt and Powerlevel10k both present**: `.zshrc` initializes Starship (`eval "$(starship init zsh)"` line 209), but `.p10k.zsh` (1600+ lines) still exists in the repo. One prompt theme is dead weight.
- **`oh-my-zsh` vestiges**: `export ZSH=~/.oh-my-zsh` is set on line 5 then `unset ZSH` on line 162 and `DISABLE_AUTO_UPDATE=true` on line 199. These are leftovers from a migration away from oh-my-zsh and serve no purpose.

### `precmd` / `preexec` Hooks Overwritten

- `.zshrc` lines 229-230 define bare `precmd()` and `preexec()` functions that only set cursor shape. This **overwrites** any hooks set by Starship or other plugins instead of using `add-zsh-hook`. Starship uses `precmd` internally, so this is actively fragile.

### Plugin Management Mismatch

- `install.sh` creates `~/.local/share/zsh/plugins/` and comments out manual `git clone` commands (lines 62-64), but `.zshrc` uses Zap plugin manager (`plug "..."` syntax) which installs to a different location. The `install.sh` plugin setup is dead code.

### Commented-Out `tmux.conf` Embedded Shell Script

- `.tmux.conf` is 1485 lines. Lines 176-1484 are a massive commented-out shell script block from gpakosz/.tmux. This is the upstream framework's engine — it works via `cut -c3-` extraction at runtime. While functional, it makes `.tmux.conf` extremely long and hard to maintain. Consider using the upstream as a git submodule instead.

### Stale Brewfile

- `Brewfile.C02FR3U9MD6T` is named with a specific hostname. The `brewup.sh` script generates these per-host, but old Brewfiles for machines no longer in use accumulate in the repo.

### `gistx()` Function Destructive Behavior

- `.zsh.functions` lines 374-382: `gistx()` does `cd /opt/gists && rm -rf .git && git init` — this destroys any existing git history in `/opt/gists` every time it runs. It also uses `clipboard` (likely undefined; should be `pbpaste`).

## Security Concerns

### Secrets File Sourced Unconditionally

- `.zshrc` line 168: `source ~/secrets.sh` — if this file contains API keys, tokens, or credentials, they're loaded into every shell session's environment. The file is not gitignored by the repo's `.gitignore` (only `.gitignore_global` covers `mySecrets.py`). If `~/secrets.sh` were accidentally committed, credentials would leak.

### Hardcoded User Paths

- `.zshrc` lines 232-233 contain fully-qualified user-specific paths:
  ```
  export CHECK_ROOT="/Users/chris.j.farrell/gits/check"
  export CHECK_PYTHON="/Users/chris.j.farrell/.virtualenvs/check-wivc/bin/python3"
  ```
  These break on any other machine and expose the username in a public repo.

### SwiftBar Slack Plugin Placeholder Credentials

- `swiftbars/slack-status.sh` line 17 contains `https://YOURUSERNAME.api.stdlib.com/slack-status@dev/` and lines 30-35 use `you@email.com` as placeholder — harmless as-is, but the script's design encourages putting real credentials inline. There's no secrets management pattern.

### `rmenv` Alias Uses `sudo rm -rf`

- `.zsh.aliases` line 54: `alias rmenv='sudo rm -rf env_*'` — glob expansion with `sudo rm -rf` is dangerous. A typo or unexpected working directory could cause serious damage. This should at minimum not use `sudo`.

### `pskill()` Uses `kill -9` Indiscriminately

- `.zsh.functions` line 289: kills all processes matching a grep pattern with `kill -9` (SIGKILL). No confirmation, no PID verification. A broad pattern like `pskill s` could kill critical system processes.

## Fragile Areas

### Vi Mode Key Bindings Order Dependency

- `.zshrc` sets emacs-style bindings first (lines 17-18: `^A`, `^E`), then more bindings (lines 176-183), then activates vi mode (`bindkey -v` on line 214) which **resets the keymap** and invalidates the earlier emacs bindings. The ordering matters and is currently wrong for the emacs bindings declared before `bindkey -v`.

### Completion System Double-Init

- `completions.zsh` calls `autoload -U compinit` (line 5), then `.zshrc` calls `autoload -Uz compinit` again (line 148) with a staleness check. The double initialization is wasteful and could cause ordering issues with completion styles (both files set `zstyle` values that may conflict).

### `audiofix` Alias Evaluated at Definition Time

- `.zsh.aliases` line 38: uses backtick command substitution inside double quotes, meaning `ps ax | grep 'coreaudiod'` runs **when the alias file is sourced**, not when the alias is invoked. The PID captured is stale by the time you use the alias.

### `fff` Alias Doesn't Work as Expected

- `.zsh.aliases` line 67: `alias fff='find / -type f -iname $1 2>/dev/null'` — aliases don't take positional parameters. `$1` expands to the shell's `$1` (usually empty), not the argument passed to `fff`. This should be a function.

### `lxt` Alias Missing Argument

- `.zsh.aliases` line 17: `alias lxt='eza --tree --level'` — the `--level` flag requires a numeric argument but none is provided. Running `lxt` alone produces an error.

### Temp File Left Behind on Failure

- `.zsh.functions` `iplist()` (line 151-169) writes to `./.tmp_ip_list.txt` in the current directory. If the function fails mid-execution, this temp file is left behind. It should use `mktemp` instead.

## Platform Portability

### macOS-Only Throughout

The entire dotfiles setup assumes macOS. Specific non-portable dependencies:

| Feature | macOS Dependency | File |
|---------|-----------------|------|
| Clipboard | `pbcopy` / `pbpaste` (8+ uses) | `.zsh.aliases`, `.zsh.functions` |
| Finder integration | `osascript` (3 uses) | `.zsh.aliases`, `.zsh.functions` |
| DNS flush | `dscacheutil -flushcache` | `.zsh.aliases` line 37 |
| Bluetooth | `blueutil` | `.zsh.aliases` line 39 |
| Audio fix | `coreaudiod` | `.zsh.aliases` line 38 |
| Image paste | AppleScript clipboard API | `.zsh.functions` `impaste()` |
| VPN interface | `utun8` hardcoded | `.zsh.functions` `dualping()` |
| Homebrew paths | `/opt/homebrew/` throughout | `.zshrc` |
| `stat -f` syntax | BSD stat (not GNU) | `.zshrc` line 149 |

### Kali Linux Support Deleted

- The `Kali/` directory has been deleted from the working tree (git status shows `D Kali/*`) but not yet committed. This was the only cross-platform support in the repo.

### `brewup.sh` PATH Assumptions

- `brewup.sh` line 2 hardcodes a PATH that includes `/Users/${USER}/.local/bin`, which is fine, but doesn't include `/opt/homebrew/bin` for Apple Silicon macs — it relies on the `arch` check on line 5, which wouldn't work on Intel macs that also need Homebrew.

## Maintenance Burden

### `.tmux.conf` — 1485 Lines

- The bulk is the gpakosz/.tmux framework embedded as commented shell code. Personal customizations are only about 50 lines at the end of `.tmux.conf.local`. The framework is effectively vendored inline rather than managed as a dependency, making updates painful.

### `.p10k.zsh` — ~1600 Lines of Unused Config

- This Powerlevel10k configuration file is still in the repo despite the switch to Starship. It's large, not sourced anywhere in `.zshrc`, and purely dead weight.

### `.zsh.functions` Contains Specialized Security Tooling

- Functions like `cve40438()` (80 lines, lines 478-558), `csrf()`, `sessionid()`, `whocerts()`, `grepip()`, `grepeml()` are security-focused tools that could be split into a separate sourced file (e.g., `.zsh.security`) to keep general-purpose functions manageable.

### `iTermProfiles.json`

- This is a large JSON file with iTerm2 profiles. Changes to it produce noisy diffs and it's machine-specific (contains host-specific font sizes, color schemes). Consider managing via iTerm2's built-in profile sync instead.

## Missing Features

### No Idempotent Install

- `install.sh` has no checks for already-installed packages. Running it twice would re-install everything. It also doesn't install Zap (the plugin manager that `.zshrc` depends on), install tmux plugins (TPM), or set up the tmux framework.

### No Uninstall / Rollback

- There's no script to remove symlinks or restore original configs if the dotfiles cause problems.

### No Symlink Management

- `install.sh` uses `cp` to copy files (lines 86-90) rather than symlinks. This means edits to the repo don't propagate to `~/` automatically, and edits in `~/` don't propagate back. A tool like `stow`, `rcm`, or a custom symlink script would fix this.

### No `.gitignore` for `.planning/` or `.claude/`

- The `.claude/` directory is untracked (shown in git status). Neither `.claude/` nor `.planning/` are in `.gitignore`, which may cause accidental commits of agent artifacts.

### `brewup.sh` Does Not Handle Casks

- The script updates formulae but doesn't explicitly handle `brew upgrade --cask` for GUI applications.

### No Shell Startup Profiling

- No `zprof` or timing instrumentation to detect slow startup. The README claims "fast startup time" but there's no way to verify or debug regressions.

### Missing `secrets.sh` Template

- `install.sh` creates an empty `~/secrets.sh` but there's no template or documentation about what variables it should contain or what format to use.

## Deleted / Orphaned Content

### Kali/ Directory (Deleted, Uncommitted)

Git status shows all Kali/ files as deleted but not committed:
- `Kali/.tmux.conf.local`
- `Kali/.zsh.aliases`
- `Kali/.zsh.functions`
- `Kali/.zshrc`
- `Kali/README.md`
- `Kali/install.sh`

These deletions should be committed to keep the repo clean. If Kali support is being dropped intentionally, the README should be updated to reflect macOS-only scope.

### `.p10k.zsh` — Orphaned

- Not sourced by `.zshrc`. Appears to be a leftover from before the Starship migration. Should be deleted or moved to an archive.

### `.claude/` Directory — Untracked

- Shown as `?? .claude` in git status. This contains agent configuration and should either be committed intentionally or added to `.gitignore`.

### `Brewfile.C02FR3U9MD6T` — Machine-Specific

- Brewfile dump for a specific hostname. If this machine is retired, the file is orphaned. The `brewup.sh` script generates new ones per-host but never cleans up old ones.
