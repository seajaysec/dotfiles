# Conventions

> Last mapped: 2026-04-21

## Shell Scripting Style

### Shebang Lines
- Standalone scripts use `#!/bin/bash` (`install.sh`, `brewup.sh`, all `swiftbars/` scripts)
- Sourced zsh config files (`.zshrc`, `.zsh.aliases`, `.zsh.functions`, `completions.zsh`) have no shebang — they are sourced into the running zsh session, not executed directly

### Error Handling in Scripts
- `install.sh` uses `set -e` for fail-fast behavior
- `brewup.sh` does **not** use `set -e`, relying instead on per-command error suppression with `2>/dev/null` and `2>&1`
- Functions in `.zsh.functions` use explicit `return 1` after printing an error message rather than relying on `set -e`

### Quoting
- Double-quoting of variables is used in most function definitions (`"$1"`, `"$input"`, `"$domain"`)
- Alias definitions sometimes omit quoting inside subshells or backtick expansions, especially for older/simpler aliases
- Backticks (`` ` ` ``) are used alongside `$()` — no strict preference enforced; newer functions prefer `$()`

### Variable Naming
- **Local variables** inside functions: `snake_case` with `local` keyword (e.g., `local volume_name`, `local target`, `local count`)
- **Environment exports** in `.zshrc`: `UPPER_SNAKE_CASE` (e.g., `GOROOT`, `BUN_INSTALL`, `PYENV_ROOT`)
- **Color variables** in `brewup.sh`: bare lowercase names (`red`, `green`, `yellow`, `blue`, `reset`) — no `local` scope

## Alias Conventions

### Naming Patterns
- **Short mnemonics** preferred: 2-5 characters (`lx`, `lxl`, `lxt`, `de`, `tm`, `gaf`, `gaa`)
- **Compound names** concatenate the tool name with the action: `dockstop`, `dockrm`, `flushDNS`, `btfix`
- **camelCase** appears for multi-word system aliases: `flushDNS`, `publicip`, `audiofix`
- **Git aliases** follow the oh-my-zsh `g`-prefix convention: `gaa` (git add all), `gaf` (git add force), `gcx` (clone)

### Grouping and Organization
Aliases in `.zsh.aliases` are organized into clearly labeled sections with comment headers:

```
# System Commands Enhancement
# File Navigation & Listing
# Network Tools & Information
# Network Monitoring & Security
# System Maintenance
# Development & Git
# Docker Management
# Python & Virtual Environment
# Text Processing & Clipboard
# Terminal & Session Management
# File Search & Navigation
# Ensure Command Interoperability
# Git Aliases
```

### Inline Documentation
Every alias has a trailing comment explaining what it does, right-aligned with padding:

```bash
alias cp='cp -iv'                           # Interactive and verbose copy
```

The comment column is loosely aligned around column 45-50 using spaces.

### Git Alias Sub-organization
Git aliases have a secondary header with workflow stage labels:

```bash
# Git Aliases
# ---------------------
# Organized by workflow stages: Basic Operations, Branching, Commits,
# Remote Operations, History & Logs, Changes & Staging, and Advanced Operations
```

## Function Conventions

### Structure
Functions in `.zsh.functions` follow a consistent pattern:

1. **Section header comment** (category with dashes):
   ```bash
   # File System Operations
   # ---------------------
   ```
2. **Doc comment** with function name, description, and usage:
   ```bash
   # mcd: Make directory and change into it
   # Usage: mcd new_directory
   ```
3. **Function body** using `funcname() { ... }` syntax (no `function` keyword)
4. **Parameter validation** at the top of the function
5. **Error messages** printed to stdout with descriptive text
6. **Return 1** on error, implicit return 0 on success

### Parameter Handling
- Input validation with `[ -z "$1" ]` guard clauses
- Usage strings printed on missing arguments: `echo "Usage: funcname <arg>"`
- Default values using `${1:-default}` syntax (e.g., `local target="${1:-8.8.8.8}"`)
- `shift` used for variadic argument handling

### Local Variables
Functions consistently use `local` to scope variables:

```bash
whocerts() {
    local domain=$1
    ...
}
```

### Complex Functions
Larger functions like `cve40438` use:
- `while [[ $1 ]]` loops with `case` for flag parsing (`-i`, `-f`, `-o`)
- Nested helper functions defined within the parent function (`probe()`, `scan_host()`)
- CSV output accumulation with `printf '%s,%s,...\n'`

### Completion Integration
Custom functions that parallel builtins get completion forwarded:

```bash
compdefas () {
  if (($+_comps[$1])); then
    compdef $_comps[$1] ${^@[2,-1]}=$1
  fi
}
compdefas mkdir mcd
```

## Configuration Style

### `.zshrc` Section Organization
The `.zshrc` file is organized into clearly delineated blocks using boxed comment headers:

```bash
###############################
# Core Environment Variables
###############################
```

Sections appear in dependency order:
1. Core Environment Variables
2. FZF configuration
3. Homebrew settings
4. Path Configuration (with `typeset -U path` for dedup)
5. Language-Specific Settings (Golang, Mono, Bun)
6. History Configuration
7. Plugin Management (via zap)
8. Source Configurations (secrets, aliases, functions)
9. Key Bindings
10. Async Load External Tools
11. Performance Improvements
12. Better Terminal Experience
13. Vi Mode Configuration

### Tmux Configuration
- `.tmux.conf` is a third-party framework (gpakosz/.tmux) — **not modified directly**
- All customization goes in `.tmux.conf.local`, which is sourced at the end
- `.tmux.conf.local` uses the same section-header pattern with dashed separators:
  ```
  # -- navigation ----------------------------------------------------------------
  # -- display -------------------------------------------------------------------
  # -- clipboard -----------------------------------------------------------------
  ```
- Plugin declarations grouped together, settings grouped after plugins
- Personal additions marked with `##### my stuff #####`

### SwiftBar/xbar Scripts
Scripts in `swiftbars/` follow xbar plugin metadata conventions:

```bash
# <xbar.title>Plugin Name</xbar.title>
# <xbar.version>v1.0</xbar.version>
# <xbar.author>Author Name</xbar.author>
# <xbar.author.github>github_username</xbar.author.github>
# <xbar.desc>Description</xbar.desc>
```

### Brewfile Management
`brewup.sh` auto-generates `Brewfile.${HOSTNAME}` per machine, dumps current state, and commits to git.

## Error Handling

### Functions Pattern
The dominant pattern is **guard clause + return 1**:

```bash
if [ -z "$1" ]; then
    echo "Usage: funcname <arg>"
    return 1
fi
```

For multi-step operations, each step checks success before proceeding:

```bash
if ! diskutil unmount "$volume_name"; then
    echo "Failed to unmount $volume_name."
    return 1
fi
```

### Command Existence Checks
Two patterns are used:
- `command -v <tool> >/dev/null 2>&1` (preferred in functions, e.g., `fatsort_volume`)
- `which <tool>` (used in `brewup.sh` — older style)
- `! command -v git >/dev/null 2>&1` (used in `install.sh`)

### Timeout Guards
Long-running network commands use `timeout` to prevent hangs:

```bash
timeout 15 openssl s_client ...
timeout 10 nslookup ...
timeout 30 nmap ...
```

### Silent Failures
Some operations intentionally suppress errors:
- `2>/dev/null` on optional tool checks
- `|| true` to prevent non-zero exit from breaking flow (e.g., `nslookup ... || true`)

## Documentation

### README
`README.md` is comprehensive and structured as a setup guide with:
- Prerequisites section with install commands
- Core Installation with `brew install` blocks
- Post-Installation Setup steps
- Features list
- Usage Notes and caveats
- Maintenance commands

### Inline Comments
- **Aliases**: Every alias has a trailing `#` comment explaining purpose
- **Functions**: Block comment above each function with name, description, and usage examples
- **`.zshrc`**: Section headers with `###############################` box-style borders
- **`.tmux.conf`**: Dashed-line section separators: `# -- section name ---`
- **`brewup.sh`**: Sparse comments using `##` prefix for section breaks

### Section Header Styles by File

| File | Style | Example |
|------|-------|---------|
| `.zsh.aliases` | `# Category Name` | `# System Commands Enhancement` |
| `.zsh.functions` | `# Category Name` + `# ---------------------` | `# Network & IP Operations` |
| `.zshrc` | `###############################` box | `# Core Environment Variables` |
| `.tmux.conf` | `# -- name ---...---` dashes | `# -- navigation ---` |
| `brewup.sh` | `##` double-hash | `## Brew packages update` |

### Color-Coded Output
Scripts use colored output for status messages:
- `install.sh`: Emoji prefixes for visual scanning (`🚀`, `📦`, `🍺`, `🔧`, `✨`)
- `brewup.sh`: tput color codes (`${yellow}==>${reset}`, `${green}==>${reset}`)
- `.zsh.functions`: Echo with color variables in `bcbc()`, emoji in `dualping()`

## File Organization

### Repository Structure
```
dotfiles/
├── .zshrc                    # Main shell config (sourced as ~/.zshrc)
├── .zsh.aliases              # All alias definitions (sourced by .zshrc)
├── .zsh.functions            # All function definitions (sourced by .zshrc)
├── .tmux.conf                # Tmux framework (upstream, do not edit)
├── .tmux.conf.local          # Tmux personal customizations
├── .gitignore_global          # Global gitignore (macOS + Python + Vim + VSCode)
├── completions.zsh           # Zsh completion configuration
├── install.sh                # One-shot setup script
├── brewup.sh                 # Homebrew update + Brewfile dump
├── config/starship/starship.toml  # Starship prompt config
├── swiftbars/                # xbar/SwiftBar menu bar plugins
│   ├── tail.5s.sh
│   ├── slack-status.sh
│   ├── mac-mux.sh
│   └── zoom.1s.scpt
└── README.md
```

### Separation of Concerns
- **Aliases** and **functions** are in dedicated files, not mixed into `.zshrc`
- **Secrets** are kept in `~/secrets.sh` (outside the repo, sourced at runtime)
- **Tmux framework** vs **personal overrides** are cleanly separated (`.tmux.conf` vs `.tmux.conf.local`)
- **Machine-specific** Brewfiles are generated per hostname (`Brewfile.${HOSTNAME}`)
