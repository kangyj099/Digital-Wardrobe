#!/usr/bin/env python3
"""PreToolUse hook: gates git/gh actions per the project's branch policy.

See docs/knowledge/reference/policy/Workflow_Project.md §13.
- `git commit` on a `feature/*` branch: allowed, no gate.
- `git commit` directly on `dev` or `main`: blocked, needs report + human confirmation.
- `gh pr create` targeting `dev` (or any non-`main` base): allowed, no gate.
- `gh pr create` targeting `main` (or with no `--base`, which defaults to the
  repo's default branch `main`): blocked, needs PR draft + report + human confirmation.
- `gh pr merge` (any direction): always blocked. Not a confirm-and-retry gate —
  the human merges directly, the AI never runs this command.
- `git push` targeting `main`: blocked, needs report + human confirmation.

Matching is done per shell segment (split on `&&`, `||`, `;`, `|`), against
only the leading command of each segment (after stripping simple `VAR=val`
prefixes) — not a substring search over the whole raw command text. This
avoids false-triggering on commands that merely *mention* a trigger phrase
inside a quoted argument (e.g. a commit message, a grep pattern, or PR body
text containing the words "gh pr merge") rather than actually invoking it.
It does not handle every shell construct (e.g. a heredoc body that itself
contains literal `&&`/`;`/`|` characters may still split oddly) — see
TechnicalDebt.md for the residual raw-text-matching limitation.
"""
import json
import re
import subprocess
import sys

SEGMENT_SPLIT_RE = re.compile(r"&&|\|\||[;|]")
LEADING_ENV_RE = re.compile(r"^(?:\w+=\S*\s+)+")

COMMIT_RE = re.compile(r"^git\s+commit\b")
PR_CREATE_RE = re.compile(r"^gh\s+pr\s+create\b")
PR_MERGE_RE = re.compile(r"^gh\s+pr\s+merge\b")
PR_BASE_RE = re.compile(r"--base[=\s]+(\S+)")
PUSH_RE = re.compile(r"^git\s+push\b")
MAIN_TOKEN_RE = re.compile(r"(?<![\w-])main(?![\w-])")


def command_segments(command):
    segments = []
    for raw_segment in SEGMENT_SPLIT_RE.split(command):
        segment = LEADING_ENV_RE.sub("", raw_segment.strip(), count=1)
        segments.append(segment)
    return segments


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

    segments = command_segments(command)

    for segment in segments:
        if PR_MERGE_RE.match(segment):
            print(
                "STOP: `gh pr merge` is never run by AI agents in this "
                "project's harness (Workflow_Project.md §13.3: the human "
                "always merges, directly on GitHub or by running this "
                "command themselves). This is not a confirm-and-retry gate "
                "— do not retry this command.",
                file=sys.stderr,
            )
            return 2

    for segment in segments:
        if PR_CREATE_RE.match(segment):
            base_match = PR_BASE_RE.search(segment)
            base = base_match.group(1).strip("'\"") if base_match else None
            if base is None or MAIN_TOKEN_RE.search(base):
                print(
                    "STOP: `gh pr create` targeting `main` (or with no "
                    "`--base` given, which defaults to this repo's default "
                    "branch, `main`) is gated by this project's harness "
                    "(main is release-only). Before creating the PR: (1) "
                    "write a PR draft (title, description, summary of "
                    "changes) and a report covering what is being released "
                    "and why, (2) show it to the user and get explicit "
                    "confirmation. Only after that, retry.",
                    file=sys.stderr,
                )
                return 2

    for segment in segments:
        if PUSH_RE.match(segment) and MAIN_TOKEN_RE.search(segment):
            print(
                "STOP: `git push` targeting `main` is gated by this "
                "project's harness (main is release-only). Before pushing: "
                "(1) write a report covering what is being released and "
                "why, (2) show it to the user and get explicit "
                "confirmation. Only after that, retry.",
                file=sys.stderr,
            )
            return 2

    for segment in segments:
        if COMMIT_RE.match(segment):
            branch = get_current_branch()
            if branch is None:
                print(
                    "STOP: could not determine the current git branch, so "
                    "this project's harness cannot verify it is safe to "
                    "commit here. Before committing: (1) write a report "
                    "covering what was done, what changed and why, and the "
                    "impact, (2) show it to the user and get explicit "
                    "confirmation. Only after that, retry the commit.",
                    file=sys.stderr,
                )
                return 2
            if branch in ("dev", "main"):
                print(
                    f"STOP: direct `git commit` on `{branch}` is gated by "
                    "this project's harness (dev/main only take changes via "
                    "PR). Before committing: (1) write a report covering "
                    "what was done, what changed and why, and the impact, "
                    "(2) show it to the user and get explicit confirmation. "
                    "Only after that, retry the commit. If this work "
                    "belongs in a feature branch instead, create one off "
                    "dev and commit there freely.",
                    file=sys.stderr,
                )
                return 2

    return 0


if __name__ == "__main__":
    sys.exit(main())
