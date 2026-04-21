# Integrations

> Last mapped: 2026-04-21

## External Services

### DNS & Network Lookup
- **OpenDNS** — `publicip` alias queries `resolver1.opendns.com` for public IP detection (`.zsh.aliases`)
- **Google DNS (8.8.8.8)** — default target in `dualping` function (`.zsh.functions`)

### Slack API
- **Autocode / stdlib** — `swiftbars/slack-status.sh` posts to `https://YOURUSERNAME.api.stdlib.com/slack-status@dev/` to change Slack status (template, requires user configuration)

### Homebrew Remote
- **GitHub (raw.githubusercontent.com)** — Homebrew install script fetched in `install.sh`
- **Homebrew taps** — various GitHub-hosted taps including `lencx/chatgpt`, `mongodb/brew`, `qmk/qmk`

### Package Registries
- **NVM (nvm-sh)** — Node version manager installed from `raw.githubusercontent.com/nvm-sh/nvm/` in `install.sh`
- **Bun** — installed from `bun.sh/install` in `install.sh`
- **Rustup** — Rust toolchain installed from `sh.rustup.rs` in `install.sh`
- **PyPI** — Python packages installed via pip/pipreqs/pip-tools (`pipr` alias in `.zsh.aliases`)

### Cloud & Productivity (via Mac App Store / Brewfile)
- **1Password** — password manager (Safari extension + CLI cask)
- **LastPass** — password manager (cask)
- **Box Drive** — cloud storage (cask)
- **Microsoft Teams / To Do** — collaboration (cask + MAS)
- **Slack** — messaging (cask)
- **Webex** — video conferencing (cask)
- **Zoom** — video conferencing (monitored by `swiftbars/zoom.1s.scpt`)
- **Spotify** — music (cask)
- **Kagi Search** — search engine (MAS)
- **Raindrop.io** — bookmarks (MAS extension)
- **Matter** — read-it-later (MAS extension)
- **Pocket** — read-it-later (MAS)

## Development Tools

### Editors & IDEs
- **VS Code** — primary editor; 109 extensions tracked in Brewfile, workspace theme via `.vscode/settings.json` (Peacock yellow), includes Dracula Pro theme
- **Neovim** — `neovim` in Brewfile
- **Vim** — configured as `$EDITOR` and `$VISUAL` in `.zshrc`
- **Sublime Text** — `sublime-text` cask in Brewfile
- **Xcode** — via Mac App Store in Brewfile
- **Qt Creator** — `qt-creator` cask in Brewfile

### VS Code Extensions (Notable)
- **GitHub Copilot + Chat** — AI pair programming (`github.copilot`, `github.copilot-chat`)
- **GitLens** — git supercharge (`eamodio.gitlens`)
- **Python** — MS Python stack (`ms-python.python`, `ms-python.vscode-pylance`, `ms-python.debugpy`, `ms-python.isort`, `ms-python.black-formatter`)
- **Jupyter** — notebook support (`ms-toolsai.jupyter` + related)
- **Docker** — container management (`ms-azuretools.vscode-docker`)
- **Remote SSH/Containers** — remote development (`ms-vscode-remote.remote-ssh`, `ms-vscode-remote.remote-containers`)
- **Live Share** — collaborative editing (`ms-vsliveshare.vsliveshare`)
- **GitLab Workflow** — GitLab integration (`gitlab.gitlab-workflow`)
- **GitHub PR** — PR management (`github.vscode-pull-request-github`)
- **REST Client / Thunder Client** — HTTP testing (`humao.rest-client`, `rangav.vscode-thunder-client`)
- **Go** — Go language support (`golang.go`)
- **PlantUML / Mermaid** — diagramming (`jebbs.plantuml`, `bierner.markdown-mermaid`)
- **Splunk** — log analysis (`splunk.splunk`, `arcsector.vscode-splunk-search-syntax`)
- **Tenable** — vulnerability scanning syntax (`tenable.vscode-auditlang`)

### Container & Virtualization
- **Docker** — `docker` cask in Brewfile; aliases `dockstop`, `dockrm` in `.zsh.aliases`
- **OrbStack** — Docker Desktop alternative (`orbstack` cask)
- **Colima / Lima** — lightweight container runtimes in Brewfile
- **VMware Fusion** — `vmware-fusion` cask in Brewfile
- **QEMU** — `qemu` in Brewfile

### Git Tools
- **Git** — core VCS; extensive aliases in `.zsh.aliases` (gaa, gcx, gaf, etc.)
- **Git LFS** — large file storage (`git-lfs` in Brewfile)
- **git-delta** — enhanced diffs
- **gh** — GitHub CLI
- **GitHub Desktop** — `github` cask in Brewfile

## Shell Plugins & Extensions

### Zsh Plugins (via Zap)
| Plugin | Source | Purpose |
|--------|--------|---------|
| `fast-syntax-highlighting` | `zdharma-continuum/fast-syntax-highlighting` | Real-time command syntax highlighting |
| `zsh-autosuggestions` | `zsh-users/zsh-autosuggestions` | Fish-like history-based suggestions |
| `zsh-history-substring-search` | `zsh-users/zsh-history-substring-search` | Incremental history search with up/down arrows |
| `zsh-you-should-use` | `MichaelAquilina/zsh-you-should-use` | Reminds about existing aliases |
| `zsh-autoswitch-virtualenv` | `MichaelAquilina/zsh-autoswitch-virtualenv` | Auto-activate Python venvs per directory |

### Tmux Plugins (via TPM)
| Plugin | Purpose |
|--------|---------|
| `tpm` | Tmux Plugin Manager |
| `tmux-autoreload` (`b0o/tmux-autoreload`) | Auto-reload config on change |
| `tmux-resurrect` | Persist tmux sessions across restarts |
| `tmux-continuum` | Continuous auto-save (1-minute interval) + auto-restore |
| `tmux-logging` | Session logging to `~/tmuxlogs` |
| `tmux-copycat` | Regex search in tmux |
| `tmux-yank` | System clipboard integration |
| `tmux-sessionist` | Session management utilities |
| `tmux-open` | Open highlighted file/URL |
| `tmux-pop` | Quick popup terminal |
| `tmux-better-mouse-mode` | Enhanced mouse support |
| `extrakto` (`laktak/extrakto`) | Extract text from terminal with fzf |
| `tmux-menus` (`jaclu/tmux-menus`) | Context menus for tmux |

### SwiftBar Plugins
| Plugin | File | Refresh | Purpose |
|--------|------|---------|---------|
| Zoom Status | `swiftbars/zoom.1s.scpt` | 1s | Shows mic/video/screen share state in menu bar |
| Log Tail | `swiftbars/tail.5s.sh` | 5s | Tails a log file in menu bar |
| Slack Status | `swiftbars/slack-status.sh` | Manual | Set Slack status from menu bar |
| Mac-Mux | `swiftbars/mac-mux.sh` | Manual | Manage tmux sessions from menu bar |

## CLI Tools

### Modern Unix Replacements
| Classic | Replacement | Alias/Config Location |
|---------|-------------|----------------------|
| `ls` | `eza` | `lx`, `lxl`, `lxt` in `.zsh.aliases` |
| `cat` | `bat` | `$PAGER`, `$MANPAGER` in `.zshrc` |
| `grep` | `ripgrep` (`rg`) | used throughout `.zsh.functions` |
| `find` | `fd` | in Brewfile |
| `cd` | `zoxide` (`z`) | `alias cd='z'` in `.zsh.aliases` |
| `diff` | `delta` | git diff pager |
| `man` | `tldr` | in Brewfile; updated via `bubu` alias |
| `top` | `bottom` (`btm`) | in Brewfile |
| `du` | `dust` / `duf` | in Brewfile |
| `ps` | `procs` | in Brewfile |
| `ls` (tree) | `erdtree` | in Brewfile |

### Network & Security Functions (`.zsh.functions`)
| Function | Purpose |
|----------|---------|
| `dualping` | Ping via both VPN and regular interface |
| `localip` | List local IPs with labels |
| `iplist` | Expand CIDR to IP list using nmap |
| `grepip` | Extract IPv4/IPv6 addresses from text |
| `grepeml` | Extract email addresses from text |
| `whocerts` | SSL certificate inspection (openssl + nslookup + nmap) |
| `cve40438` | Apache CVE-2021-40438 SSRF scanner |
| `csrf` | Extract CSRF tokens from cookie files |

### File & Productivity Functions (`.zsh.functions`)
| Function | Purpose |
|----------|---------|
| `mcd` | mkdir + cd combined |
| `m2d` | Markdown to DOCX via pandoc |
| `mp4togif` | MP4 to GIF via ffmpeg + imagemagick |
| `impaste` | Save clipboard image to file via osascript |
| `pb2csv` | Convert clipboard lines to CSV |
| `fatsort_volume` | Sort FAT volume files |
| `remove_dups` | Find and remove duplicate files via MD5 |
| `finish-branch` | Merge branch to main, push, and clean up |
| `ipy` | Smart iPython launcher respecting virtualenvs |

### macOS Utilities (`.zsh.aliases`)
| Alias | Purpose |
|-------|---------|
| `flushDNS` | Clear macOS DNS cache |
| `audiofix` | Reset coreaudiod |
| `btfix` | Reset Bluetooth via blueutil |
| `bubu` | Update tldr + run brewup |
| `f` | Jump to current Finder window directory |

### Keyboard & Input Hardware
- **QMK** — custom keyboard firmware (`qmk/qmk` tap, `qmk-toolbox` cask, `qflipper` cask)
- **Karabiner-Elements** — keyboard remapping (cask)
- **BetterTouchTool** — input customization (cask)
- **Hammerspoon** — macOS automation (cask)
- **Via** — keyboard configuration (cask)

### macOS Window & System Management
- **Magnet** — window management (MAS)
- **Alfred** — launcher/automation (cask)
- **OnyX** — system maintenance (cask)
- **Macs Fan Control** — thermal management (cask)
- **AppCleaner** — app removal (cask)
- **Shottr** — screenshot tool (cask)
- **Kap** — screen recording (cask)

### Browsers
- **Arc** — primary browser (cask)
- **Google Chrome** — (cask)
- **Firefox** — (cask)
- **Chromium** — (cask)
- **Vivaldi** — (cask)
- **Microsoft Edge** — (cask)
- **Browsh** — terminal-based browser (brew tap)
- **w3m** — text browser (brew)

### Safari Extensions (via MAS)
- AdGuard, Dark Reader, Ghostery, Hush, StopTheMadness, Tampermonkey, Vinegar, Wipr, 1Password, Auto HD FPS for YouTube
