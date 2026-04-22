# Requirement waivers (explicit, not silent)

| ID | Original requirement | Waiver | Rationale |
|----|------------------------|--------|-----------|
| DEAD-04 | Remove `source ~/secrets.sh` | **Keep** `~/secrets.sh` sourced from `.zshrc` | User policy: secrets stay local and untracked; removing the source line would break real workflows. |

Update `REQUIREMENTS.md` trace tables only when closing Phase 5, with a pointer to this file.
