#!/usr/bin/env python3
"""Stop hook: non-blocking reminder if docs/work/BACKLOG.md looks stale vs HEAD.

Fires on every Stop event. Only emits a systemMessage (never blocks) when
BACKLOG.md's last touching commit is more than STALE_COMMIT_THRESHOLD commits
behind the current branch tip - a cheap proxy for "real progress happened
that BACKLOG.md doesn't reflect yet."
"""
import json
import subprocess

STALE_COMMIT_THRESHOLD = 5
BACKLOG_PATH = "docs/work/BACKLOG.md"


def git(*args):
    try:
        return subprocess.run(
            ["git", *args], capture_output=True, text=True, check=True
        ).stdout.strip()
    except (subprocess.CalledProcessError, FileNotFoundError):
        return ""


def main():
    root = git("rev-parse", "--show-toplevel")
    if not root:
        print(json.dumps({}))
        return

    head = git("-C", root, "log", "-1", "--format=%H")
    backlog_commit = git("-C", root, "log", "-1", "--format=%H", "--", BACKLOG_PATH)

    if not head or not backlog_commit or backlog_commit == head:
        print(json.dumps({}))
        return

    count_str = git("-C", root, "rev-list", "--count", f"{backlog_commit}..HEAD")
    count = int(count_str) if count_str.isdigit() else 0

    if count >= STALE_COMMIT_THRESHOLD:
        print(json.dumps({
            "systemMessage": (
                f"docs/work/BACKLOG.md is {count} commits behind HEAD. "
                "If a task paused mid-way or a decision was made since the last "
                "BACKLOG.md update, record it there before this session's context "
                "is lost (see CLAUDE.md's session-continuity note)."
            )
        }))
    else:
        print(json.dumps({}))


if __name__ == "__main__":
    main()
