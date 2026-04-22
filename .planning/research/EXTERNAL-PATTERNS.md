# External patterns & public dotfiles

**Status:** Populated **2026-04-21** (Phase 8 / `EXT-01`–`EXT-03`).

## Stack overlap criteria

macOS, zsh, heavy aliases/functions, optional: Zap, Starship, fzf, security tooling, Homebrew.

## References reviewed (≥5)

| # | Source | Stack overlap |
|---|--------|----------------|
| 1 | https://github.com/mathiasbynens/dotfiles | macOS defaults, bootstrap script, `~/.path` / `~/.extra` local hooks |
| 2 | https://github.com/romkatv/zsh-defer | zsh performance, deferred `source` after first prompt |
| 3 | https://github.com/romkatv/zsh-bench | quantitative zsh startup measurement |
| 4 | https://www.devtoolsguide.com/zsh-setup-guide | Starship + minimal plugin set, anti-bloat narrative |
| 5 | https://github.com/jesseduffield/lazynvim (ecosystem) | parallel: “lazy” loading culture — defer non-critical work until idle |

## Adopt

| Source | Pattern | Rationale | Effort |
|--------|---------|-----------|--------|
| mathiasbynens/dotfiles | `bootstrap.sh` + optional `~/.extra` for machine-local | Mirrors our `~/.zshrc.local` / secrets split; clear install story | S |
| romkatv/zsh-defer | Wrap rare heavy `source` lines with defer | Optional next milestone if Zap grows; keep in backlog | M |
| romkatv/zsh-bench | Cold/warm `zsh -i -c exit` sampling script | Aligns with PERF work; adopt measurement snippets only | S |
| Community Starship docs | Keep prompt init **after** tool `eval`s | Already applied (ARCH-06) | — |

## Reject

| Source | Pattern | Rationale |
|--------|---------|-----------|
| Heavy OMZ bundles | Dozens of default plugins | Conflicts with DEAD-* / startup goals; we removed OMZ exports |
| Powerlevel10k instant prompt | p10k instant + zsh semantics | Repo deleted `.p10k.zsh`; Starship is the chosen prompt stack |
| Copy-only install without backup | blind `cp ~/.zshrc` | Replaced with symlink + `~/.dotfiles-backup/` (Phase 6) |

## Defer

| Source | Pattern | Next step |
|--------|---------|-----------|
| Zinit / Antidote | Turbo / bundle compile | Evaluate only if Zap becomes bottleneck; add GSD backlog item |
| Nix/Home-manager | declarative shells | Large migration; defer to future milestone |
| fish abbr model | abbr vs alias | Different shell; note for cross-shell machines only |

## ROADMAP / backlog

- [ ] Optional: add `zsh-defer` spike after Phase 5 if `time zsh -i -c exit` regresses (owner: next milestone).
