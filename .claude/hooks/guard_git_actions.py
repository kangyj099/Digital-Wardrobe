#!/usr/bin/env python3
"""PreToolUse hook: gates git/gh actions per the project's branch policy.

See docs/knowledge/reference/policy/Workflow_Project.md §13.
- `git commit` on a `feature/*` branch: allowed, no gate.
- `git commit` directly on `dev` or `main`: blocked, needs report + human confirmation.
- `gh pr create` (any direction): blocked, needs PR draft + report + human confirmation.
- `git push` targeting `main`: blocked, needs report + human confirmation.
"""
import json
import re
import subprocess
import sys

COMMIT_RE = re.compile(r"\bgit\s+commit\b")
PR_CREATE_RE = re.compile(r"\bgh\s+pr\s+create\b")
PUSH_RE = re.compile(r"\bgit\s+push\b")
MAIN_TOKEN_RE = re.compile(r"(?<![\w-])main(?![\w-])")


def get_current_branch():
    try:
        result = subprocess.run(
            ["git", "rev-parse", "--abbrev-ref", "HEAD"],
            capture_output=True,
            text=True,
            check=True,
        )
        return result.stdout.strip()
    except (subprocess.CalledProcessError, FileNotFoundError):
        return None


def main() -> int:
    raw = sys.stdin.read()
    try:
        payload = json.loads(raw)
    except json.JSONDecodeError:
        return 0

    command = payload.get("tool_input", {}).get("command", "")
    if not command:
        return 0

    if PR_CREATE_RE.search(command):
        print(
            "STOP: `gh pr create` is gated by this project's harness. "
            "Before creating the PR: (1) write a PR draft (title, description, "
            "summary of changes) and a report covering what was done, why, and "
            "the impact, (2) show it to the user and get explicit confirmation. "
            "Only after that, retry.",
            file=sys.stderr,
        )
        return 2

    if PUSH_RE.search(command) and MAIN_TOKEN_RE.search(command):
        print(
            "STOP: `git push` targeting `main` is gated by this project's "
            "harness (main is release-only). Before pushing: (1) write a "
            "report covering what is being released and why, (2) show it to "
            "the user and get explicit confirmation. Only after that, retry.",
            file=sys.stderr,
        )
        return 2

    if COMMIT_RE.search(command):
        branch = get_current_branch()
        if branch is None:
            print(
                "STOP: could not determine the current git branch, so this "
                "project's harness cannot verify it is safe to commit here. "
                "Before committing: (1) write a report covering what was "
                "done, what changed and why, and the impact, (2) show it to "
                "the user and get explicit confirmation. Only after that, "
                "retry the commit.",
                file=sys.stderr,
            )
            return 2
        if branch in ("dev", "main"):
            print(
                f"STOP: direct `git commit` on `{branch}` is gated by this "
                "project's harness (dev/main only take changes via PR). "
                "Before committing: (1) write a report covering what was "
                "done, what changed and why, and the impact, (2) show it to "
                "the user and get explicit confirmation. Only after that, "
                "retry the commit. If this work belongs in a feature branch "
                "instead, create one off dev and commit there freely.",
                file=sys.stderr,
            )
            return 2
        return 0

    return 0


if __name__ == "__main__":
    sys.exit(main())
