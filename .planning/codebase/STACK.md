# Tech Stack

> Last mapped: 2026-04-21

## Languages & Runtimes

- **Zsh** — primary shell, configured via `.zshrc` with vi-mode, extended globbing, and extensive history tuning
- **Bash** — used in helper scripts (`brewup.sh`, `install.sh`, swiftbar plugins)
- **AppleScript/osascript** — used in `swiftbars/zoom.1s.scpt` and clipboard functions in `.zsh.functions`
- **Python** — multiple versions managed via pyenv (`python@3.9`, `3.10`, `3.11`, `3.12` in Brewfile); `PYENV_ROOT` configured in `.zshrc`
- **Go** — `GOROOT=/usr/local/go`, `GOPATH=$HOME/go` configured in `.zshrc`; `go` and `go-bindata` in Brewfile
- **Rust/Cargo** — installed via rustup; `~/.cargo/bin` on PATH in `.zshrc`
- **Bun** — JavaScript runtime at `$HOME/.bun`, on PATH in `.zshrc`
- **Node.js** — via `node` in Brewfile; NVM installed by `install.sh`
- **Lua** — `lua` in Brewfile
- **V (vlang)** — `vlang` in Brewfile

## Package Management

- **Homebrew** — primary package manager for macOS; `/opt/homebrew/bin` (Apple Silicon) on PATH
  - `Brewfile.C02FR3U9MD6T` — machine-specific bundle dump (466 lines) covering brew formulae, casks, Mac App Store apps, and VS Code extensions
  - `brewup.sh` — automated update script that runs `brew update/upgrade/cleanup`, generates a new Brewfile dump per hostname, and commits to git
  - `install.sh` — bootstrap script installing essential packages, dev tools, and shell config
- **Homebrew taps:** `abhimanyu003/sttr`, `browsh-org/browsh`, `buo/cask-upgrade`, `homebrew/bundle`, `homebrew/cask-drivers`, `homebrew/cask-fonts`, `homebrew/services`, `lencx/chatgpt`, `mongodb/brew`, `osx-cross/arm`, `osx-cross/avr`, `qmk/qmk`
- **Mac App Store (mas)** — managed via `mas` CLI; 48 apps tracked in Brewfile
- **pip / pipreqs / pip-tools** — Python dependency management via `pipr` alias in `.zsh.aliases`
- **pyenv / pyenv-virtualenv** — Python version and virtualenv management; lazy-loaded wrapper in `.zshrc`
- **Poetry** — Python packaging (`poetry` in Brewfile)
- **uv** — fast Python package manager (`uv` in Brewfile)
- **Cargo** — Rust package manager (via rustup)
- **npm** — `~/.npm-packages/bin` on PATH
- **Zap** — zsh plugin manager (`~/.local/share/zap/zap.zsh`); manages plugins via `plug` command in `.zshrc`
- **TPM** — tmux plugin manager (`~/.tmux/plugins/tpm`); 14 plugins declared in `.tmux.conf.local`

## Frameworks & Tools

- **Starship** — cross-shell prompt; config at `config/starship/starship.toml` with Gruvbox Dark palette, Nerd Font symbols, git/python/package/cmd_duration/status modules
- **tmux** — terminal multiplexer; base config from [gpakosz/.tmux](https://github.com/gpakosz/.tmux) in `.tmux.conf`, customized in `.tmux.conf.local` with Dracula-inspired color scheme, mouse support, status bar at top, 1M line history
- **fzf** — fuzzy finder; configured in `.zshrc` with ag backend, bat preview, and key bindings
- **zoxide** — smart `cd` replacement; aliased as `cd` in `.zsh.aliases`
- **SwiftBar** — macOS menu bar plugin system; 4 plugins in `swiftbars/` (Zoom status, log tail, Slack status, tmux session manager)
- **iTerm2** — terminal emulator; profile config in `iTermProfiles.json`, shell integration sourced in `.zshrc`

## Key Dependencies

### CLI Tools (installed via Homebrew)

| Tool | Purpose |
|------|---------|
| `bat` | cat replacement with syntax highlighting; used as PAGER and MANPAGER |
| `eza` | modern ls replacement (aliased as `lx`, `lxl`, `lxt`) |
| `ripgrep` (`rg`) | fast grep replacement; used extensively in functions |
| `fd` | modern find replacement |
| `the_silver_searcher` (`ag`) | code searching; fzf default command |
| `delta` (`git-delta`) | better git diffs |
| `tldr` | simplified man pages |
| `nmap` | network scanning; used in `iplist`, `whocerts`, `cve40438` functions |
| `jq` / `ijq` | JSON processing |
| `grc` | generic colorizer for nmap output |
| `pandoc` | document conversion; used by `m2d` function |
| `ffmpeg` / `imagemagick` | media conversion; used by `mp4togif` function |
| `blueutil` | Bluetooth control; used by `btfix` alias |
| `shellcheck` / `shfmt` | shell script linting and formatting |
| `gh` | GitHub CLI |
| `starship` | prompt |
| `highlight` | source code highlighter |

### Security & Pentesting Tools

| Tool | Purpose |
|------|---------|
| `nmap` | network scanner |
| `masscan` | fast port scanner |
| `bettercap` | network attack framework |
| `hashcat` / `john-jumbo` | password cracking |
| `gobuster` / `feroxbuster` | directory brute-forcing |
| `wpscan` | WordPress scanner |
| `shodan` | Shodan CLI |
| `burp-suite` (cask) | web app testing |
| `ghidra` (cask) | reverse engineering |
| `wireshark` (cask + brew) | packet analysis |
| `binwalk` | firmware analysis |
| `foremost` | file carving |
| `fcrackzip` | zip password cracking |
| `samba` | SMB utilities |

### Database Tools

| Tool | Purpose |
|------|---------|
| `postgresql@14` | PostgreSQL database (Homebrew service) |
| `pgcli` / `pgadmin4` | PostgreSQL clients |
| `mongodb-community` | MongoDB (via tap) |
| `mongosh` | MongoDB shell |
| `neo4j` / `cypher-shell` | Graph database + query shell |
| `redis` | In-memory data store |
| `dbeaver-community` (cask) | Universal database GUI |
| `azure-data-studio` (cask) | SQL Server / Azure GUI |

## Configuration Approach

### File Structure

```
dotfiles/
├── .zshrc                          # Main shell config (sourced as ~/.zshrc)
├── .zsh.aliases                    # Aliases (sourced from .zshrc)
├── .zsh.functions                  # Functions (sourced from .zshrc)
├── .tmux.conf                      # tmux base config (gpakosz fork)
├── .tmux.conf.local                # tmux local overrides + plugins
├── .p10k.zsh                       # Powerlevel10k config (legacy, replaced by Starship)
├── .fzf.zsh                        # fzf setup (legacy, now using `source <(fzf --zsh)`)
├── .gitignore_global               # Global gitignore (macOS, Python, VS Code, Vim)
├── completions.zsh                 # Zsh completion system config
├── config/starship/starship.toml   # Starship prompt config
├── install.sh                      # Bootstrap installer
├── brewup.sh                       # Homebrew update + Brewfile dump + git push
├── Brewfile.C02FR3U9MD6T           # Machine-specific Brewfile
├── iTermProfiles.json              # iTerm2 profile export
├── swiftbars/                      # SwiftBar/xbar menu bar plugins
│   ├── zoom.1s.scpt                # Zoom meeting status indicator
│   ├── tail.5s.sh                  # Log tail in menu bar
│   ├── slack-status.sh             # Slack status setter
│   └── mac-mux.sh                  # tmux session manager
└── .vscode/settings.json           # VS Code workspace theme (Peacock)
```

### Sourcing Chain

1. `~/.zshrc` loads (symlinked from `dotfiles/.zshrc`)
2. Sets env vars, PATH, Homebrew, pyenv, Go, Bun, Cargo
3. Loads Zap plugin manager, then 5 zsh plugins via `plug`
4. Sources `~/dotfiles/completions.zsh`
5. Sources `~/secrets.sh` (not tracked, holds API keys/tokens)
6. Sources `~/dotfiles/.zsh.aliases` and `~/dotfiles/.zsh.functions`
7. Integrates fzf, iTerm2 shell integration, Bun completions, Cargo env, zoxide
8. Initializes Starship prompt
9. Configures vi-mode key bindings and cursor shape

### Install Mechanism

- `install.sh` bootstraps from scratch: Xcode CLT, Homebrew, essential brew packages, NVM, Bun, Rust, directory structure, config file copies, fzf setup, zsh as default shell
- `brewup.sh` handles ongoing maintenance: updates brew, dumps current Brewfile per hostname, commits and pushes to git
- Configs live in `~/dotfiles/` and are sourced by reference (not symlinked via stow or similar)
