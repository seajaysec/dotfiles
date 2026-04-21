---
phase: 1
slug: critical-startup-fixes
status: draft
nyquist_compliant: false
wave_0_complete: true
created: 2026-04-21
---

# Phase 1 — Validation Strategy

> Per-phase validation contract for shell startup work (no application test suite).

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | none — shell / zsh |
| **Config file** | n/a |
| **Quick run command** | `time zsh -i -c exit` |
| **Full suite command** | Same as quick + PATH duplicate check + tool probes (see Per-Task map) |
| **Estimated runtime** | ~5-15 seconds (including 3× timing) |

---

## Sampling Rate

- **After every task commit:** Run `time zsh -i -c exit` once
- **After every plan wave:** Run full suite (3× timing median, PATH uniq -d, tool `command -v` checks)
- **Before `/gsd-verify-work`:** Full suite must meet ROADMAP success criteria
- **Max feedback latency:** < 30 seconds

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| T-01-01-a | 01 | 1 | PERF-02 | — | N/A | grep | No line matching `agent shell-integration` in `~/dotfiles/.zshrc` nor in `~/.zshrc` | ✅ | ⬜ pending |
| T-01-01-b | 01 | 1 | PERF-01 | — | N/A | timing | `time zsh -i -c exit` records real time | ✅ | ⬜ pending |
| T-01-02-a | 02 | 2 | PERF-03 | — | N/A | grep | If `~/.zshenv` exists: no line containing `.cargo/env` | ✅ | ⬜ pending |
| T-01-02-b | 02 | 2 | PERF-04 | — | N/A | grep | If `~/.zshenv` exists: no line containing `.bun/_bun` | ✅ | ⬜ pending |
| T-01-02-c | 02 | 2 | PERF-05 | — | N/A | grep | `grep -c '^export PATH=' ~/dotfiles/.zshrc` ≤ 3 and less than logged `baseline_export_path_count` | ✅ | ⬜ pending |
| T-01-02-d | 02 | 2 | PERF-01 | — | N/A | timing | `time zsh -i -c exit` | ✅ | ⬜ pending |
| T-01-03-a | 03 | 3 | PERF-06 | — | N/A | grep | `! grep -q '^MANPATH=' ~/dotfiles/.zshrc` | ✅ | ⬜ pending |
| T-01-03-b | 03 | 3 | PERF-07 | — | N/A | shell | `ls ~/.zcompdump* 2>/dev/null \| wc -l` → expect ≤ 1 active policy per CONTEXT | ✅ | ⬜ pending |
| T-01-03-c | 03 | 3 | PERF-04, PERF-03 | — | N/A | grep | `grep -q '\.cargo/env' ~/dotfiles/.zshrc` AND `grep -q '\.bun/_bun\|_bun' ~/dotfiles/.zshrc` | ✅ | ⬜ pending |
| T-01-03-d | 03 | 3 | PERF-05 | — | N/A | shell | `echo "$PATH" \| tr ':' '\n' \| sort \| uniq -d` output empty | ✅ | ⬜ pending |
| T-01-03-e | 03 | 3 | PERF-01 | — | N/A | timing | median of 3× `time zsh -i -c exit` < 200ms real | ✅ | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [x] **Existing infrastructure covers all phase requirements** — validation is CLI/benchmark only; no Wave 0 code stubs required.

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Interactive tools work | PRES-12 (sanity) | Needs human judgment on rare edge cases | Open new terminal tab; run `python3 --version`, `cargo --version`, `bun --version` once |
| Symlink deployment | INST-05 prep | Path varies by machine | `ls -la ~/.zshrc` — confirm symlink to `~/dotfiles/.zshrc` or document if not |

*If none: "All phase behaviors have automated verification."* → **False** — table above lists manual checks.

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency < 30s
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
