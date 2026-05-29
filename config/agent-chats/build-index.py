#!/usr/bin/env python3
"""Build data.js for the agent-chats viewer.

Walks an archive root whose immediate subdirectories are repos, each holding
specstory markdown sessions (copied from <repo>/.specstory/history/). Each
session's CLI tool is read from specstory's own marker comment, e.g.

    <!-- Cursor CLI Session 8f20c944-... (2026-05-26 16:18:57Z) -->

The whole index *and* each file's markdown is baked into

    window.ARCHIVE = { generated, root, entries: [...] };

so the viewer works over file:// with no server and no fetch() (browsers block
XHR/fetch for local files; <script src> is fine).

Usage: build-index.py [ARCHIVE_ROOT]   (default: cwd)
"""
from __future__ import annotations

import datetime as _dt
import json
import re
import sys
from pathlib import Path

# Infra files that live in the archive root alongside repo subdirs — never repos.
SKIP_NAMES = {"viewer.html", "data.js", "build-index.py", "collect-native.py",
              "marked.min.js", "purify.min.js", "vendor"}

# specstory writes: <!-- <Tool Name> Session <uuid> (<timestamp>) -->
TOOL_RE = re.compile(r"<!--\s*(.+?)\s+Session\s+[0-9a-fA-F-]{8,}", re.IGNORECASE)
SESSION_RE = re.compile(r"Session\s+([0-9a-fA-F-]{8,})", re.IGNORECASE)
# filenames: 2026-05-26_16-26-56Z[-optional-slug].md
NAME_RE = re.compile(r"^(\d{4}-\d{2}-\d{2})_(\d{2})-(\d{2})-(\d{2})Z(?:-(.*))?$")


def parse_session(text: str) -> str:
    m = SESSION_RE.search(text)
    return m.group(1).lower() if m else ""


def sort_epoch(stem: str, fallback: float) -> float:
    """Sort key from the filename timestamp; fall back to file mtime."""
    m = NAME_RE.match(stem)
    if not m:
        return fallback
    date, hh, mm, ss, _ = m.groups()
    try:
        return _dt.datetime.strptime(f"{date} {hh}{mm}{ss}", "%Y-%m-%d %H%M%S") \
            .replace(tzinfo=_dt.timezone.utc).timestamp()
    except ValueError:
        return fallback


def parse_tool(text: str) -> str:
    m = TOOL_RE.search(text)
    return m.group(1).strip() if m else "Unknown"


def parse_title(stem: str) -> tuple[str, str]:
    """Return (display_time, slug_title) from a session filename stem."""
    m = NAME_RE.match(stem)
    if not m:
        return stem, ""
    date, hh, mm, ss, slug = m.groups()
    when = f"{date} {hh}:{mm}:{ss}Z"
    title = slug.replace("-", " ").strip() if slug else ""
    return when, title


def build(root: Path) -> dict:
    entries = []
    for repo_dir in sorted(p for p in root.iterdir() if p.is_dir() and p.name not in SKIP_NAMES):
        for md in sorted(repo_dir.rglob("*.md")):
            try:
                text = md.read_text(encoding="utf-8", errors="replace")
            except OSError:
                continue
            when, title = parse_title(md.stem)
            entries.append({
                "repo": repo_dir.name,
                "tool": parse_tool(text),
                "file": md.name,
                "when": when,
                "title": title or md.stem,
                "mtime": sort_epoch(md.stem, md.stat().st_mtime),
                "session": parse_session(text),
                "content": text,
            })
    # Dedupe sessions that appear from more than one collector (e.g. specstory's
    # claude output and the native Claude collector share a session id). Keep the
    # richest copy.
    best = {}
    passthrough = []
    for e in entries:
        sid = e.get("session")
        if not sid:
            passthrough.append(e)
            continue
        cur = best.get(sid)
        if cur is None or len(e["content"]) > len(cur["content"]):
            best[sid] = e
    entries = passthrough + list(best.values())
    # newest first
    entries.sort(key=lambda e: e["mtime"], reverse=True)
    return {
        "generated": _dt.datetime.now().astimezone().isoformat(timespec="seconds"),
        "root": str(root),
        "entries": entries,
    }


def main(argv: list[str]) -> int:
    root = Path(argv[1]).expanduser().resolve() if len(argv) > 1 else Path.cwd()
    if not root.is_dir():
        print(f"build-index: not a directory: {root}", file=sys.stderr)
        return 1
    data = build(root)
    payload = "window.ARCHIVE = " + json.dumps(data, ensure_ascii=False) + ";\n"
    (root / "data.js").write_text(payload, encoding="utf-8")
    print(f"build-index: {len(data['entries'])} session(s) -> {root / 'data.js'}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main(sys.argv))
