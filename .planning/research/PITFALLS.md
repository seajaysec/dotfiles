# Pitfalls Research

> Researched: 2026-04-21
> Sources: starship/starship#1804, starship/starship#2717, starship/starship#3418, ohmyzsh/ohmyzsh#6909, ohmyzsh/ohmyzsh#12952, zsh-users/zsh-syntax-highlighting README, unix.stackexchange.com, stackoverflow.com, various dotfiles guides

---

## Startup Hang Causes

### 1. `eval` Subshells That Spawn Processes

**What goes wrong:** Commands like `eval "$(tool init zsh)"` fork a subprocess, run the tool, capture stdout, then eval the output. Each one adds 10–200ms. Chaining several (nvm, pyenv, rbenv, starship, zoxide, fzf) accumulates to multi-second startup.

**How to detect:** Profile with `zprof`:
```zsh
zmodload zsh/zprof   # top of .zshrc
# ... rest of config ...
zprof                 # bottom of .zshrc
```
Or time individual evals: `time eval "$(starship init zsh)"`.

**How to fix:**
- **Cache eval output:** Use `evalcache` plugin or manually cache: run `tool init zsh > ~/.cache/tool-init.zsh` and source the cached file. Regenerate on tool upgrade.
- **Lazy-load version managers:** Don't run `eval "$(pyenv init -)"` at startup. Define a wrapper function that loads on first use. (This project already does this for pyenv — good.)
- **Use `source <(tool --zsh)` vs `eval`:** Process substitution (`source <(fzf --zsh)`) is marginally faster than eval since it avoids the eval parse step, but both still fork. The real win is caching.

**This project:** The Cursor agent `eval "$(~/.local/bin/agent shell-integration zsh)"` takes 1.47s and uses `exec` to replace the shell process — this is the primary hang. Starship (54ms), zoxide (11ms), fzf (21ms) are acceptable.

### 2. Network-Dependent Operations at Startup

**What goes wrong:** Plugin managers that `git clone` on first load, tools that phone home for update checks, or DNS lookups in prompt functions will hang if the network is slow or unavailable.

**How to detect:** Start a shell with Wi-Fi off. If it hangs or takes >5s, something is network-dependent.

**How to fix:** Ensure plugin installation is a separate explicit step, not triggered by shell startup. Disable auto-update in plugin managers (`DISABLE_AUTO_UPDATE=true`). Never put `curl`/`wget` calls in `.zshrc`.

### 3. Multiple `compinit` Calls

**What goes wrong:** `compinit` scans all `fpath` directories, reads completion functions, and optionally writes a dump file. Running it twice doubles this cost (50–200ms each).

**How to detect:** `grep -n 'compinit' ~/.zshrc` — if you see it more than once, or in both `.zshrc` and a sourced file, it's doubling.

**How to fix:** Call `compinit` exactly once, after all `fpath` modifications. Use daily-cache pattern:
```zsh
autoload -Uz compinit
if [[ -n ~/.zcompdump(#qN.mh+24) ]]; then
  compinit
else
  compinit -C
fi
```

**This project:** `completions.zsh` runs `autoload -U compinit` (line 5) and `.zshrc` runs it again (line 148). The `completions.zsh` call doesn't invoke compinit but loads it, then `.zshrc` conditionally runs it. However, `completions.zsh` also sets `zstyle` rules that conflict with `.zshrc`'s `zstyle` rules.

### 4. MANPATH Pipeline at Source Time

**What goes wrong:** `.zshrc` line 90–93 runs `manpath | tr | grep | paste` every shell startup — a 4-process pipeline that blocks until complete.

**How to detect:** Comment it out and measure time difference.

**How to fix:** Cache the result, or simply `export MANPATH` without the filtering pipeline. If the TeX manpath is the only issue, remove it from `/etc/manpaths.d/` instead.

### 5. Stale `.zcompdump` Files

**What goes wrong:** Multiple `.zcompdump` files accumulate (different zsh versions, hostnames). Old dumps may reference completion functions that no longer exist, causing errors or slow fallback to full scan.

**How to detect:** `ls -la ~/.zcompdump*` — if there are more than one, or if the timestamp is months old, they're stale.

**How to fix:** Clean up on upgrade: `rm -f ~/.zcompdump*; exec zsh`. Consider naming the dump file explicitly: `compinit -d ~/.zcompdump-${ZSH_VERSION}`.

**This project:** Four stale `.zcompdump` files exist on disk.

---

## Keybinding Pitfalls

### 1. `bindkey -v` Wipes All Previous Bindings

**What goes wrong:** `bindkey -v` switches the main keymap to `viins` (vi insert mode). Any bindings set with `bindkey` before this call were applied to the *emacs* keymap. After `bindkey -v`, those bindings are invisible because you're now in a different keymap.

**How to detect:** Set a binding before `bindkey -v`, then check: `bindkey | grep your-key`. It won't appear.

**How to fix:** Always call `bindkey -v` FIRST, then set all custom bindings. For emacs-style convenience bindings in vi mode, explicitly target the `viins` keymap:
```zsh
bindkey -v                              # switch to vi mode FIRST
bindkey -M viins '^A' beginning-of-line # now add emacs conveniences
bindkey -M viins '^E' end-of-line
bindkey -M viins '^[[A' history-substring-search-up
```

**This project:** `.zshrc` sets `bindkey "^A" beginning-of-line` on line 17 and `bindkey "^E" end-of-line` on line 18, but `bindkey -v` doesn't appear until line 214. All bindings between lines 17–183 are set in the emacs keymap and then abandoned when vi mode activates. This is the exact bug described in PROJECT.md.

### 2. `EDITOR`/`VISUAL` Containing "vi" Triggers Vi Mode

**What goes wrong:** Zsh reads `EDITOR` and `VISUAL` at startup. If either contains the string "vi" (including "vim"), zsh may automatically enable vi keybindings, potentially before your explicit `bindkey -v` call.

**How to detect:** `echo $EDITOR $VISUAL` — if either is `vim` or `vi`, zsh activates vi mode implicitly.

**How to fix:** This is usually fine if you *want* vi mode. But if you set `EDITOR=vim` early and then do `bindkey -e` (emacs mode) later, the implicit vi activation may interfere. Set `EDITOR`/`VISUAL` after your `bindkey` mode selection, or accept that vi mode is the intended default.

**This project:** `EDITOR=vim` and `VISUAL=vim` are set on lines 10–11. Since vi mode is desired, this is consistent — but it means vi mode may activate before `bindkey -v` on line 214, making the ordering even more critical.

### 3. `KEYTIMEOUT` Too Low

**What goes wrong:** `KEYTIMEOUT` controls the delay (in hundredths of a second) zsh waits for multi-character key sequences. Setting it to 1 (10ms) makes escape sequences from terminal emulators (arrow keys, Home, End, etc.) unreliable because they're multi-byte sequences that arrive over multiple reads.

**How to detect:** Arrow keys or Home/End stop working intermittently, especially over SSH or in tmux.

**How to fix:** Use `KEYTIMEOUT=10` (100ms) as a safer minimum. The value `1` may work on local terminals but fails over network connections.

**This project:** `KEYTIMEOUT=1` on line 215. This is aggressive — test in tmux and SSH scenarios.

### 4. Terminal-Specific Escape Sequences

**What goes wrong:** Key sequences like `^[[A` (up arrow), `^[[H` (Home), `^[[F` (End) vary between terminal emulators (iTerm2, Terminal.app, tmux, SSH). Hardcoded sequences may not work everywhere.

**How to detect:** Press the key in `cat -v` mode to see what your terminal actually sends. Compare with what's in your bindkey.

**How to fix:** Use `$terminfo` array for portable sequences:
```zsh
bindkey "${terminfo[kcuu1]}" history-substring-search-up
bindkey "${terminfo[kcud1]}" history-substring-search-down
```

---

## Hook Function Pitfalls (precmd/preexec)

### 1. Direct `precmd()` Definition Overwrites Hook Arrays

**What goes wrong:** Defining `precmd()` as a function replaces the hook entirely. If starship (or any prompt) registered a function in `precmd_functions` array, your direct `precmd()` definition shadows the entire array mechanism. Only your function runs; starship's `prompt_starship_precmd` never fires.

**How to detect:** `echo $precmd_functions` — if it contains entries but your `precmd()` function exists, the array entries are ignored in favor of the function.

**How to fix:** Use `add-zsh-hook` instead:
```zsh
autoload -U add-zsh-hook
_cursor_precmd() { echo -ne '\e[5 q'; }
add-zsh-hook precmd _cursor_precmd
```
This appends to `precmd_functions` array without overwriting starship's hook.

**This project:** `.zshrc` line 229 defines `precmd() { echo -ne '\e[5 q'; }` which overwrites starship's precmd hook. Line 230 does the same for `preexec()`.

### 2. `zle-keymap-select` Widget Conflicts

**What goes wrong:** Only one function can be the `zle-keymap-select` widget at a time. If you define it with `zle -N zle-keymap-select your_func`, and starship also defines it, whichever runs last wins. The other's cursor shape or prompt indicator breaks.

**How to detect:** Check `widgets[zle-keymap-select]` — it shows which function is registered.

**How to fix:** Wrap the existing widget. Modern starship (post-PR#2717) preserves existing `zle-keymap-select` functions by wrapping them. Define your cursor function BEFORE `eval "$(starship init zsh)"` and starship will chain-call it. Or, define it AFTER starship and manually call starship's function:
```zsh
_my_keymap_select() {
  if [[ ${KEYMAP} == vicmd ]] || [[ $1 == 'block' ]]; then
    echo -ne '\e[1 q'
  else
    echo -ne '\e[5 q'
  fi
  # call starship's original if it exists
  if (( ${+functions[starship_zle-keymap-select-wrapped]} )); then
    starship_zle-keymap-select-wrapped "$@"
  fi
}
zle -N zle-keymap-select _my_keymap_select
```

**This project:** `.zshrc` line 220–227 defines `zle-keymap-select` and registers it with `zle -N`, but starship also registers its own. Since starship init is on line 209 and the custom widget is on line 227, the custom widget wins and starship's vi-mode indicator breaks. The correct fix: define the custom cursor widget before starship init, with a unique name, and let starship wrap it.

### 3. Infinite Recursion on Re-source

**What goes wrong:** If `zle-keymap-select` wrapping isn't guarded, re-sourcing `.zshrc` creates recursive wrapper chains: A wraps B which wraps A. This causes "maximum nested function level reached" errors.

**How to detect:** Source `.zshrc` twice in the same session and press Escape. If you get a stack overflow, wrapping is recursive.

**How to fix:** Guard with a check:
```zsh
if [[ "${widgets[zle-keymap-select]#user:}" != "starship_zle-keymap-select"* ]]; then
  zle -N zle-keymap-select ""
fi
eval "$(starship init zsh)"
```

---

## PATH Construction Pitfalls

### 1. Missing `typeset -U` on Both `PATH` and `path`

**What goes wrong:** Zsh ties `PATH` (colon-separated string) and `path` (array) together. Setting `-U` (unique) on only one doesn't fully deduplicate. String-based PATH modifications (`PATH=~/bin:$PATH`) bypass the array's unique attribute.

**How to detect:** `echo $PATH | tr ':' '\n' | sort | uniq -d` — shows duplicates.

**How to fix:** Set unique on both:
```zsh
typeset -U PATH path
```
Do this once, early in `.zshrc`, before any path modifications.

**This project:** `.zshrc` line 54 has `typeset -U path` but not `typeset -U PATH`. Lines 70, 74, 101, and 113 all do `export PATH="${path[*]}"` or `export PATH="...:$PATH"`, which can reintroduce duplicates through the string interface.

### 2. Rebuilding PATH Multiple Times

**What goes wrong:** Setting `export PATH="${path[*]}"` after every path addition forces a full rebuild of the string each time. This is unnecessary — zsh auto-syncs `path` and `PATH`. Each `export PATH=` also triggers any `PATH`-watching tools to re-evaluate.

**How to detect:** Count occurrences of `export PATH` in `.zshrc`.

**How to fix:** Set `typeset -U PATH path` once at the top. Then only use `path+=(/new/dir)` to add entries. Never manually export PATH — zsh handles the sync.

**This project:** `export PATH=` appears on lines 15, 70, 74, 101, 113. The path array is defined on lines 55–69, then immediately exported on line 70, then modified and re-exported three more times. All the intermediate exports are unnecessary.

### 3. `/etc/zprofile` and `path_helper` Reordering

**What goes wrong:** macOS runs `/etc/zprofile` in login shells, which invokes `/usr/libexec/path_helper`. This utility reads `/etc/paths` and `/etc/paths.d/*`, then *prepends* those paths before any existing PATH entries. Paths set in `.zshenv` get pushed to the end.

**How to detect:** In a login shell: `echo $PATH | tr ':' '\n' | head -5` — if `/usr/bin` appears before `/opt/homebrew/bin`, path_helper reordered you.

**How to fix:** Don't set PATH in `.zshenv` for things that must have priority. Set them in `.zshrc` (which runs after `.zprofile`). Or set them in `.zprofile` after the `path_helper` call. The loading order is: `.zshenv` → `/etc/zprofile` → `.zprofile` → `.zshrc`.

### 4. Hardcoded Absolute PATH Strings

**What goes wrong:** `export PATH="/opt/homebrew/bin:/usr/local/bin:..."` overwrites the entire PATH, discarding entries added by `.zshenv`, `.zprofile`, or system files.

**How to detect:** If tools from system paths stop working after sourcing `.zshrc`, you've overwritten PATH.

**How to fix:** Always prepend/append, never overwrite:
```zsh
path=(/opt/homebrew/bin $path)  # prepend
path+=($GOPATH/bin)             # append
```

---

## Completion System Pitfalls

### 1. `fpath` Modified After `compinit`

**What goes wrong:** `compinit` caches which completion functions exist in which `fpath` directories. If you add to `fpath` after `compinit` runs, those new directories are invisible until the next `compinit` call.

**How to detect:** New completions don't work. Check if `fpath+=` appears after `compinit` in your config.

**How to fix:** All `fpath` modifications MUST come before `compinit`. Load order:
1. Set `fpath` (all additions)
2. Call `compinit`
3. Set `zstyle` completion options

**This project:** `completions.zsh` adds `~/.zfunc` to fpath (line 2), but Docker completions may be added elsewhere after compinit. The fpath addition in `completions.zsh` runs before compinit in `.zshrc`, which is correct, but any late fpath modifications are lost.

### 2. `$ZSH_CACHE_DIR` Undefined

**What goes wrong:** `zstyle ':completion::complete:*' cache-path $ZSH_CACHE_DIR` uses an oh-my-zsh variable. Without oh-my-zsh, `$ZSH_CACHE_DIR` is empty, so the cache path resolves to an empty string or root directory.

**How to detect:** `echo $ZSH_CACHE_DIR` — if empty, the zstyle is broken.

**How to fix:** Define it yourself or use a literal path:
```zsh
zstyle ':completion::complete:*' cache-path "${XDG_CACHE_HOME:-$HOME/.cache}/zsh"
```

**This project:** `completions.zsh` line 13 references `$ZSH_CACHE_DIR`. The main `.zshrc` sets `export ZSH=~/.oh-my-zsh` (line 5) but then `unset ZSH` (line 162). `ZSH_CACHE_DIR` is never defined.

### 3. Conflicting `zstyle` Rules

**What goes wrong:** Multiple `zstyle` rules for the same completion context override each other. The last one wins, but it's hard to track which file sets which rule.

**How to detect:** `zstyle -L ':completion:*'` — review for duplicate or conflicting patterns.

**How to fix:** Consolidate all `zstyle` rules in one place, after `compinit`.

**This project:** `completions.zsh` sets formatting zstyles (lines 16–27) and `.zshrc` sets different formatting zstyles (lines 154–161). They use different format strings for the same contexts (e.g., `:completion:*:descriptions`). The `.zshrc` ones win since they're sourced later, making the `completions.zsh` ones dead code.

---

## Plugin Loading Pitfalls

### 1. Syntax Highlighting Must Be Last

**What goes wrong:** `zsh-syntax-highlighting` works by wrapping ZLE widgets. If loaded before other plugins that create widgets (autosuggestions, history-substring-search), it can't wrap them, and highlighting breaks for those interactions.

**How to detect:** Syntax highlighting doesn't colorize certain input patterns, or autosuggestion acceptance breaks highlighting.

**How to fix:** Always load `zsh-syntax-highlighting` (or `fast-syntax-highlighting`) as the LAST plugin:
```zsh
plug "zsh-users/zsh-autosuggestions"
plug "zsh-users/zsh-history-substring-search"
plug "zdharma-continuum/fast-syntax-highlighting"   # LAST
```

**This project:** `.zshrc` loads `fast-syntax-highlighting` FIRST (line 141), before autosuggestions (line 142) and history-substring-search (line 143). This is backwards. Move it to last.

### 2. Plugin Manager Network Dependency

**What goes wrong:** Some plugin managers (including Zap) will `git clone` plugins on first run. If the network is unavailable, the shell hangs or throws errors during startup.

**How to detect:** Delete `~/.local/share/zap/plugins/` and start a shell without internet.

**How to fix:** Pre-install plugins as an explicit setup step (in `install.sh`), not implicitly during shell startup. Guard plugin loading: `[[ -d "$plugin_dir" ]] && source "$plugin_dir/plugin.zsh"`.

### 3. history-substring-search Requires Bindings After Load

**What goes wrong:** `history-substring-search` creates the `history-substring-search-up` and `history-substring-search-down` widgets when sourced. If you `bindkey` to these widgets before the plugin loads, the bindings silently fail.

**How to detect:** Arrow keys don't do substring search. Check if `bindkey` for these appears before the `plug` call.

**How to fix:** Bind after loading: place `bindkey '^[[A' history-substring-search-up` after the `plug` line.

**This project:** Bindings are on lines 176–177, after plugins on lines 141–145. This is correct.

---

## Alias Pitfalls

### 1. `$1` in Aliases Doesn't Work

**What goes wrong:** Aliases are simple text substitution — they don't receive arguments. `$1` in an alias refers to the shell's positional parameters, not the alias's arguments.

**How to detect:** The alias ignores its argument or uses a stale/empty value.

**How to fix:** Convert to a function:
```zsh
# WRONG:
alias fff='find / -type f -iname $1 2>/dev/null'

# RIGHT:
fff() { find / -type f -iname "$1" 2>/dev/null; }
```

**This project:** `.zsh.aliases` line 67 defines `alias fff='find / -type f -iname $1 2>/dev/null'`. The `$1` is always empty (expands to the shell's `$1`, not the alias argument). Must be converted to a function.

### 2. Backtick Evaluation at Definition Time

**What goes wrong:** In double-quoted aliases, backticks (`` ` ` ``) are evaluated when the alias is *defined*, not when it's *used*. The captured value is baked into the alias permanently.

**How to detect:** The alias always returns the same value regardless of current state.

**How to fix:** Use `$(...)` instead of backticks, and use single quotes to prevent expansion at definition time:
```zsh
# WRONG (double quotes + backticks = evaluated NOW):
alias audiofix="sudo kill -9 `ps ax | grep 'coreaudiod' | grep -v grep | awk '{print $1}'`"

# RIGHT (single quotes + $() = evaluated at USE time):
alias audiofix='sudo kill -9 $(pgrep coreaudiod)'
# Or better, make it a function:
audiofix() { sudo kill -9 $(pgrep coreaudiod); }
```

**This project:** `.zsh.aliases` line 38 defines `audiofix` with backtick evaluation in double quotes. The `ps | grep | awk` pipeline runs when `.zshrc` is sourced, not when the alias is invoked. The PID captured is stale by the time you use the alias.

### 3. Recursive Aliases

**What goes wrong:** Aliasing a command to itself plus flags (e.g., `alias grep='grep --color=auto'`) can cause infinite recursion in some shells. Zsh handles simple cases, but complex chains (alias A calls B which calls A) can loop.

**How to detect:** Command hangs or produces "maximum recursion depth" error.

**How to fix:** Use `command` to bypass alias lookup:
```zsh
alias grep='command grep --color=auto'
```
Or use `\grep` to escape alias expansion.

### 4. `clipsort` Double-Quote Nesting

**What goes wrong:** `alias clipsort="pbpaste | grep -v "^$" | sort -Vu | pbcopy"` — the inner double quotes around `^$` terminate the outer double quotes. The alias definition is broken.

**How to detect:** `which clipsort` shows unexpected value.

**How to fix:** Use single quotes for the outer wrapper, or escape the inner quotes:
```zsh
alias clipsort='pbpaste | grep -v "^$" | sort -Vu | pbcopy'
```

**This project:** `.zsh.aliases` line 58 has this exact nested double-quote issue.

---

## Deployment Pitfalls

### 1. Copy-Based Deploy Causes Divergence

**What goes wrong:** `cp dotfiles/.zshrc ~/.zshrc` creates an independent copy. Edits to `~/.zshrc` (by tools, agents, or manual tweaks) diverge from the repo. Edits to the repo don't propagate until you re-run the install script.

**How to detect:** `diff ~/dotfiles/.zshrc ~/.zshrc` — any differences mean divergence.

**How to fix:** Use symlinks: `ln -sf ~/dotfiles/.zshrc ~/.zshrc`. Changes to the repo file are immediately live. Changes to `~/.zshrc` are changes to the repo file.

**This project:** The deployed `~/.zshrc` has diverged from the repo version. The install script uses `cp`. The Cursor agent shell integration was added to the deployed copy but not the repo. This is the exact divergence problem.

### 2. Forgetting to Re-Deploy After Edits

**What goes wrong:** You edit files in the repo, commit, but forget to run the install script. Your actual shell config is stale.

**How to detect:** `diff` your repo files against deployed files.

**How to fix:** Symlinks eliminate this entirely. For files that can't be symlinked (e.g., some tools don't follow symlinks), use a post-commit hook or a watcher.

### 3. Mixed Symlinks and Copies

**What goes wrong:** Some files are symlinked (`.zsh.aliases`, `.zsh.functions`) while others are copied (`.zshrc`). This creates confusion about which files are live-linked and which require re-deployment.

**How to detect:** `ls -la ~/.zsh* ~/.zshrc` — check which are symlinks vs regular files.

**How to fix:** Be consistent. Symlink everything, or use a tool (stow, chezmoi) that handles it uniformly.

**This project:** `.zsh.aliases` and `.zsh.functions` are sourced directly from `~/dotfiles/` (already "live"). `.zshrc` is copied. The plan to switch to symlinks will fix this inconsistency.

---

## macOS-Specific Pitfalls

### 1. `/etc/zprofile` and `path_helper` Interference

**What goes wrong:** macOS ships `/etc/zprofile` which runs `/usr/libexec/path_helper -s`. This reads `/etc/paths` and `/etc/paths.d/*` and prepends those entries, pushing your custom PATH additions to the end. Load order: `.zshenv` → `/etc/zprofile` → `.zprofile` → `.zshrc`.

**How to detect:** `cat /etc/zprofile` — if it contains `path_helper`, it's active.

**How to fix:** Don't fight it. Set PATH in `.zshrc` or `.zprofile` (which run after `path_helper`), not in `.zshenv`. Or set PATH in `.zshenv` knowing it will be reordered, and re-prepend critical entries in `.zprofile`.

### 2. Wrong `ARCHFLAGS` on Apple Silicon

**What goes wrong:** `export ARCHFLAGS="-arch x86_64"` tells compilers to build for Intel, even on an ARM64 Mac. This produces x86_64 binaries that require Rosetta, or causes build failures for tools that don't support cross-compilation.

**How to detect:** `uname -m` returns `arm64` but `ARCHFLAGS` says `x86_64`.

**How to fix:**
```zsh
export ARCHFLAGS="-arch $(uname -m)"
```
Or simply: `export ARCHFLAGS="-arch arm64"` on Apple Silicon.

**This project:** `.zshrc` line 8 has `export ARCHFLAGS="-arch x86_64"` — wrong for Apple Silicon. Interestingly, `.zsh.functions` `ssdeep_env()` correctly sets it to `arm64`.

### 3. Apple's System Zsh vs Homebrew Zsh

**What goes wrong:** macOS ships zsh 5.8.x (or 5.9 on newer macOS). Homebrew installs the latest (5.9+). If your login shell is `/bin/zsh` (Apple's) but you installed Homebrew's zsh at `/opt/homebrew/bin/zsh`, you may be running the wrong version. Features, completions, and behaviors differ between versions.

**How to detect:** `which zsh` and `zsh --version` — compare with `/opt/homebrew/bin/zsh --version`.

**How to fix:** If using Homebrew zsh, add it to `/etc/shells` and set it as default:
```bash
echo /opt/homebrew/bin/zsh | sudo tee -a /etc/shells
chsh -s /opt/homebrew/bin/zsh
```

### 4. Homebrew Intel vs ARM Paths

**What goes wrong:** Intel Homebrew installs to `/usr/local`, ARM Homebrew to `/opt/homebrew`. If you migrated from Intel to ARM, or use Rosetta for some tools, both paths may exist. PATH order determines which architecture's binaries run.

**How to detect:** `file $(which python3)` — shows the binary's architecture.

**How to fix:** Ensure `/opt/homebrew/bin` appears before `/usr/local/bin` in PATH on ARM Macs.

**This project:** PATH correctly prioritizes `/opt/homebrew/bin` (line 56) over `/usr/local/bin` (line 58).

---

## Security Pitfalls

### 1. `sudo rm -rf` in Aliases

**What goes wrong:** Aliases like `alias rmenv='sudo rm -rf env_*'` are dangerous. If run from the wrong directory, or if the glob doesn't match (and `nomatch` is unset), it could delete unintended files with root privileges.

**How to detect:** `grep -n 'sudo.*rm' ~/.zsh*` — review each match.

**How to fix:** Remove `sudo` if not needed (virtualenvs are user-owned). Add safety checks:
```zsh
rmenv() {
  local dirs=(env_*(N))
  if (( ${#dirs} == 0 )); then
    echo "No env_* directories found"
    return 1
  fi
  echo "Will remove: ${dirs[*]}"
  read -q "?Proceed? [y/N] " || return
  rm -rf "${dirs[@]}"
}
```

**This project:** `.zsh.aliases` line 54: `alias rmenv='sudo rm -rf env_*'` — uses sudo unnecessarily and has no confirmation.

### 2. Secrets in Dotfiles Repos

**What goes wrong:** API keys, tokens, SSH keys, or passwords committed to a dotfiles repo. Even if the repo is private, credentials in git history persist forever unless force-purged.

**How to detect:** Run `gitleaks detect` or `trufflehog filesystem .` on the repo.

**How to fix:** Use a separate `~/.secrets.sh` (gitignored) for credentials. Source it from `.zshrc` but never commit it. Use OS keychain or `pass` for sensitive values.

**This project:** `source ~/secrets.sh` exists (line 168) but the file is empty (0 bytes). The pattern is correct but the sourcing of an empty file is unnecessary overhead.

### 3. Hardcoded Absolute Paths with Usernames

**What goes wrong:** Paths like `/Users/chris.j.farrell/.virtualenvs/...` in committed config files leak your username and home directory structure.

**How to detect:** `grep -r '/Users/' ~/dotfiles/` — find hardcoded user paths.

**How to fix:** Use `$HOME` or `~` instead of absolute paths.

**This project:** `.zshrc` lines 232–233 hardcode `/Users/chris.j.farrell/...` paths. Use `$HOME` instead.

### 4. World-Readable Dotfiles

**What goes wrong:** If `.zshrc`, secrets files, or SSH configs are world-readable (644 or 755), other users on a shared system can read your configuration and any embedded credentials.

**How to detect:** `ls -la ~/.zshrc ~/.ssh/config ~/secrets.sh` — check permissions.

**How to fix:** `chmod 600` for secrets and SSH configs. `chmod 644` for `.zshrc` is generally acceptable (no secrets should be in it).

---

## Recommendations

Specific recommendations for this project, prioritized by impact:

### Critical (Causing Active Bugs)

1. **Move `bindkey -v` to the top of the keybinding section** — before any `bindkey` calls. Then rebind all emacs-style convenience bindings with `-M viins`. This fixes the wiped-bindings bug.

2. **Replace `precmd()`/`preexec()` with `add-zsh-hook`** — define uniquely-named functions (`_cursor_shape_precmd`, `_cursor_shape_preexec`) and register with `add-zsh-hook`. This stops overwriting starship's hooks.

3. **Move `zle-keymap-select` definition BEFORE `starship init`** — give it a unique name and let starship wrap it, or define it after starship and manually chain-call starship's function.

4. **Fix `ARCHFLAGS`** — change to `"-arch arm64"` or `"-arch $(uname -m)"`.

5. **Convert `fff` alias to function** — aliases don't accept positional parameters.

6. **Fix `audiofix` alias** — backtick evaluation at definition time means stale PID. Convert to function with `$(pgrep coreaudiod)`.

### High Priority (Performance/Correctness)

7. **Remove Cursor agent shell-integration** from `.zshrc` — 1.47s + exec replacement is the primary hang.

8. **Move `fast-syntax-highlighting` to LAST in plugin list** — it must load after all other plugins to correctly wrap ZLE widgets.

9. **Consolidate PATH construction** — `typeset -U PATH path` once at top, use only `path+=(...)` for additions, never `export PATH=`.

10. **Merge `completions.zsh` into `.zshrc`** — eliminate the second `autoload compinit`, conflicting zstyle rules, and undefined `$ZSH_CACHE_DIR`.

11. **Fix `SHARE_HISTORY` + `INC_APPEND_HISTORY` conflict** — these are mutually exclusive. Remove `INC_APPEND_HISTORY` if using `SHARE_HISTORY`.

12. **Remove `HIST_STAMPS` duplication** — set on line 122 as `"yyyy-mm-dd"` and line 204 as `"mm/dd/yyyy"`. Pick one.

### Medium Priority (Cleanup/Maintenance)

13. **Switch install.sh from cp to symlinks** — prevents repo/deployed divergence.

14. **Remove all oh-my-zsh vestiges** — `export ZSH=`, `unset ZSH`, `unset ZSH_THEME`, `DISABLE_AUTO_UPDATE`.

15. **Remove dead `source ~/secrets.sh`** — file is empty.

16. **Cache MANPATH pipeline** — or remove the TeX filter and configure at the system level.

17. **Clean up stale `.zcompdump` files** — delete all and let the daily-cache pattern rebuild.

18. **Fix `clipsort` alias quoting** — nested double quotes break the alias definition.

19. **Fix `rmenv` alias** — remove unnecessary `sudo`, add confirmation.

20. **Replace hardcoded `/Users/chris.j.farrell/` with `$HOME`** — in `.zshrc` lines 232–233.
