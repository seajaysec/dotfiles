#!/usr/bin/env python3
"""Collect GUI/IDE agent chats that `specstory sync` doesn't cover and write them
into the archive as specstory-style markdown so build-index.py treats them
uniformly.

Sources:
  * Claude Code  — ~/.claude/projects/<encoded>/<session>.jsonl  (CLI + IDE/desktop
                   share this store; repo taken from each event's `cwd`).
  * Cursor IDE   — Cursor globalStorage `state.vscdb` (cursorDiskKV): each
                   `composerData:<id>` is a chat; `bubbleId:<id>:<bid>` rows are
                   its messages, ordered by `fullConversationHeadersOnly`.

Each session is written as <archive>/<repo>/<timestamp>-<slug>.md beginning with
a `<!-- <Tool> Session <id> (<when>) -->` marker. Overlap with specstory (same
Claude session) is harmless: build-index.py dedupes on the session id.

Usage: collect-native.py <ARCHIVE_ROOT>
"""
from __future__ import annotations

import datetime as _dt
import json
import re
import sqlite3
import sys
from pathlib import Path

HOME = Path.home()
CLAUDE_PROJECTS = HOME / ".claude" / "projects"
CURSOR_DB = HOME / "Library/Application Support/Cursor/User/globalStorage/state.vscdb"
# Only trust the user's real project root for repo names: /…/gits/<repo>/ with a
# trailing slash (a directory, not an attached file like /src/App.tsx).
GITS_RE = re.compile(r"/gits/([A-Za-z0-9._-]+)/")


def fmt_ts(dt: _dt.datetime) -> str:
    return dt.strftime("%Y-%m-%d_%H-%M-%S") + "Z"


def slugify(text: str, n: int = 8) -> str:
    words = re.findall(r"[A-Za-z0-9]+", (text or "").lower())
    return "-".join(words[:n])[:60]


def write_session(root: Path, repo: str, when: _dt.datetime, slug: str,
                  marker: str, body: str) -> Path:
    repo = re.sub(r"[^A-Za-z0-9._-]", "_", repo) or "_unknown"
    stem = fmt_ts(when) + (("-" + slug) if slug else "")
    d = root / repo
    d.mkdir(parents=True, exist_ok=True)
    path = d / (stem + ".md")
    header = (
        "<!-- Collected by ssync native collector -->\n\n"
        f"# {when.strftime('%Y-%m-%d %H:%M:%S')}Z\n\n"
        f"{marker}\n\n"
    )
    path.write_text(header + body, encoding="utf-8")
    return path


# --------------------------------------------------------------------------- #
# Claude Code
# --------------------------------------------------------------------------- #
def claude_text(content) -> str:
    """Flatten a Claude message `content` (str or list of blocks) to markdown."""
    if isinstance(content, str):
        return content.strip()
    if not isinstance(content, list):
        return ""
    out = []
    for b in content:
        if not isinstance(b, dict):
            continue
        t = b.get("type")
        if t == "text":
            out.append((b.get("text") or "").strip())
        elif t == "thinking":
            think = (b.get("thinking") or "").strip()
            if think:
                out.append(f"<think><details><summary>Thought</summary>\n{think}\n</details></think>")
        elif t == "tool_use":
            out.append(f"<tool-use>Tool: **{b.get('name','?')}**</tool-use>")
        elif t == "tool_result":
            r = b.get("content")
            if isinstance(r, list):
                r = " ".join(x.get("text", "") for x in r if isinstance(x, dict))
            r = (str(r) if r else "").strip()
            if r:
                out.append(f"<details><summary>Tool result</summary>\n\n```\n{r[:2000]}\n```\n</details>")
    return "\n\n".join(p for p in out if p)


def collect_claude(root: Path) -> int:
    if not CLAUDE_PROJECTS.is_dir():
        return 0
    n = 0
    for jf in CLAUDE_PROJECTS.rglob("*.jsonl"):
        try:
            events = [json.loads(l) for l in jf.read_text(encoding="utf-8", errors="replace").splitlines() if l.strip()]
        except OSError:
            continue
        cwd = next((e.get("cwd") for e in events if e.get("cwd")), None)
        sid = next((e.get("sessionId") for e in events if e.get("sessionId")), jf.stem)
        repo = Path(cwd).name if cwd else jf.parent.name.lstrip("-").split("-")[-1]
        when = None
        parts, first_user = [], ""
        for e in events:
            if e.get("type") not in ("user", "assistant"):
                continue
            msg = e.get("message")
            if not isinstance(msg, dict):
                continue
            txt = claude_text(msg.get("content"))
            if not txt or txt.startswith("<local-command"):
                continue
            ts = e.get("timestamp")
            if when is None and ts:
                try:
                    when = _dt.datetime.fromisoformat(ts.replace("Z", "+00:00"))
                except ValueError:
                    pass
            role = "User" if e.get("type") == "user" else "Agent"
            if role == "User" and not first_user:
                first_user = txt
            parts.append(f"_**{role}**_\n\n{txt}")
        if not parts:
            continue
        when = when or _dt.datetime.fromtimestamp(jf.stat().st_mtime, _dt.timezone.utc)
        marker = f"<!-- Claude Code Session {sid} ({fmt_ts(when)}) -->"
        write_session(root, repo, when, slugify(first_user), marker, "\n\n---\n\n".join(parts))
        n += 1
    return n


# --------------------------------------------------------------------------- #
# Cursor IDE
# --------------------------------------------------------------------------- #
def collect_cursor(root: Path) -> int:
    if not CURSOR_DB.exists():
        return 0
    try:
        con = sqlite3.connect(f"file:{CURSOR_DB}?mode=ro&immutable=1", uri=True)
    except sqlite3.Error:
        return 0
    n = 0
    try:
        cur = con.cursor()
        composers = cur.execute(
            "SELECT key, value FROM cursorDiskKV WHERE key LIKE 'composerData:%'"
        ).fetchall()
        for key, val in composers:
            try:
                comp = json.loads(val)
            except (json.JSONDecodeError, TypeError):
                continue
            cid = comp.get("composerId") or key.split(":", 1)[-1]
            headers = comp.get("fullConversationHeadersOnly") or []
            if not headers:
                continue
            bubbles = {}
            for bkey, bval in cur.execute(
                "SELECT key, value FROM cursorDiskKV WHERE key LIKE ?", (f"bubbleId:{cid}:%",)
            ):
                try:
                    bubbles[bkey.split(":")[-1]] = json.loads(bval)
                except (json.JSONDecodeError, TypeError):
                    continue
            parts, blob = [], []
            for h in headers:
                b = bubbles.get(h.get("bubbleId"))
                if not b:
                    continue
                txt = (b.get("text") or "").strip()
                if not txt:
                    continue
                blob.append(txt)
                role = "User" if h.get("type") == 1 else "Agent"
                parts.append(f"_**{role}**_\n\n{txt}")
            if not parts:
                continue
            ms = comp.get("createdAt") or comp.get("lastUpdatedAt") or 0
            when = _dt.datetime.fromtimestamp(ms / 1000, _dt.timezone.utc) if ms else _dt.datetime.now(_dt.timezone.utc)
            m = GITS_RE.search(" ".join(blob))
            repo = m.group(1) if m else "cursor-ide"
            name = comp.get("name") or ""
            marker = f"<!-- Cursor IDE Session {cid} ({fmt_ts(when)}) -->"
            write_session(root, repo, when, slugify(name or blob[0] if blob else ""), marker,
                          "\n\n---\n\n".join(parts))
            n += 1
    finally:
        con.close()
    return n


def main(argv: list[str]) -> int:
    if len(argv) < 2:
        print("usage: collect-native.py <ARCHIVE_ROOT>", file=sys.stderr)
        return 1
    root = Path(argv[1]).expanduser().resolve()
    root.mkdir(parents=True, exist_ok=True)
    c = collect_claude(root)
    k = collect_cursor(root)
    print(f"collect-native: Claude Code sessions={c}, Cursor IDE sessions={k}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main(sys.argv))
