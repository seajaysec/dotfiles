# External patterns & public dotfiles

**Status:** Deepened **2026-04-22** (Phase 8 reopen). Earlier version was a **surface table** only — this revision adds **actionable** patterns and **explicit non-adoptions**.

## Stack overlap criteria

macOS, zsh, heavy aliases/functions, optional: Zap, Starship, fzf, security tooling, Homebrew.

## References reviewed (≥8)

| # | Source | Stack overlap | What we extracted |
|---|--------|---------------|-------------------|
| 1 | https://github.com/mathiasbynens/dotfiles | macOS bootstrap, `brew.sh`, `~/.extra` | Split **bootstrap** vs **repeatable link**; local extras file name varies (`~/.extra` vs our `~/.zshrc.local`). |
| 2 | https://github.com/holman/dotfiles | Topic dirs, `*.symlink` → `$HOME`, ordered zsh loads | **Path before completion** ordering matches our ARCH narrative; **topic modularity** is a v2 refactor (high churn for this repo today). |
| 3 | https://github.com/wincent/wincent | Long-lived dotfiles, **zprof** / `PS4` timing, restrained zsh | **Profiling workflow**: uncomment `zmodload zsh/zprof` + `zprof` when debugging — adopt as **doc + commented block** optional, not default (noise). |
| 4 | https://github.com/romkatv/zsh-defer | Defer `source` until idle | Use when a **single** slow line dominates; wrong if sprinkled everywhere (ordering bugs). **Defer** until a measured offender exists. |
| 5 | https://github.com/romkatv/zsh-bench | Quantitative startup metrics | Standardize on **`zsh-bench`** (or `hyperfine`) before trying zsh-defer/Zinit — **measure first** on this machine after each phase. |
| 6 | https://www.devtoolsguide.com/zsh-setup-guide | Starship + small plugin set | Validates our “Zap + few plugs + fsh last” direction; no new tool. |
| 7 | https://github.com/golangci/golangci-lint (ecosystem) | Modern Go dev on macOS | Indirect: **`fd`/`ripgrep`** already align with “fast CLI” stacks; no config change. |
| 8 | https://github.com/vitejs/vite (ecosystem) | JS tooling velocity | **Reject for shell**: no benefit to zshrc; kept to show we **filtered** irrelevant “popular repos”. |

## Patterns worth copying (Adopt / partial adopt)

| Pattern | Where seen | Fit for this repo | Integrated? |
|---------|------------|-------------------|-------------|
| **`DOTFILES` env** + default `$HOME/dotfiles` | Common in bootstrap repos (mathias/holman variants) | Non-secret portable root for `source` paths | **Yes** — `.zshenv` exports `DOTFILES`; `.zshrc` uses `"${DOTFILES}/…"`. |
| **`install.sh --link-only`** | Implicit in holman/mathias “re-run bootstrap” split | Fast, safe re-run on existing machines | **Yes** — `install.sh` implements `--link-only`. |
| **Symlink + backup** | holman `script/bootstrap` spirit | Avoid drift between repo and `$HOME` | **Yes** — `~/.dotfiles-backup/<ts>/`. |
| **zsh-bench before micro-optimizing** | romkatv | Stops cargo-cult defer | **Doc only** — run manually; add to `07-VERIFICATION.md` when closing Phase 7. |
| **Topic-based zsh layout** | holman | Maintainability | **Defer** — would restructure hundreds of lines; schedule v2 if pain is real. |

## Reject (explicit)

| Pattern | Why not (for you now) |
|---------|----------------------|
| **Zinit turbo everywhere** | Complexity + different mental model from Zap; only revisit if Zap becomes measurable bottleneck. |
| **p10k instant prompt** | Conflicts with Starship-first choice; already removed. |
| **fish / nushell migration** | Out of scope (macOS zsh). |

## Defer (backed by rationale)

| Item | Next step |
|------|-----------|
| **romkatv/zsh-defer** | Run `zsh-bench`; if one source line dominates **>30ms**, wrap **only that line** behind `zsh-defer`. |
| **zcompile `.zshrc`** | Run after layout stabilizes (Phase 7 sign-off); invalidate on every edit — easy to get wrong. |
| **Holman-style topic split** | Open a **v2** milestone if `.zshrc` editing conflict rate stays high. |

## Honest EXT-03 accounting

- **Integrated from public patterns in this pass:** `DOTFILES` default + **`install.sh --link-only`** + expanded symlink set (aliases/functions/starship/tmux) — inspired by common bootstrap repos, not “novel research.”
- **Not integrated (deliberately):** `zsh-defer`, Zinit, topic-directory rewrite — need **measurement** first.

## ROADMAP / backlog

- [ ] v2: Holman-style topic split **if** `.zshrc` churn stays painful after Phase 7.
- [ ] v2: `zsh-defer` on worst **one** slow `source` line after `zsh-bench` proves it.
