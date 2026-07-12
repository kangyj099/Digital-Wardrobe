#!/usr/bin/env python3
"""Stop hook: suggests /clear or a new session right after a task boundary.

Fires on every Stop event. Emits a systemMessage (never blocks) when the
current HEAD commit itself touched docs/work/BACKLOG.md - a proxy for
"a task/cycle was just marked complete" (Workflow_Project.md §10: BACKLOG.md's
Current section is updated as part of closing out a task step, not as an
afterthought). False positives are possible (e.g. a pure formatting edit to
BACKLOG.md also touches it) - this is a nudge, not a hard signal.
"""
import json
import subprocess

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

    if head and backlog_commit == head:
        print(json.dumps({
            "systemMessage": (
                   "docs/work/BACKLOG.md가 방금 커밋에서 갱신됐습니다. - 작업 경계로 보입니다. "
                "다음 작업으로 넘어가기 전 /clear로 컨텍스트를 비우거나 새 세션을 여는 걸 권장합니다."
            )
        }))
    else:
        print(json.dumps({}))

if __name__ == "__main__":
    main()