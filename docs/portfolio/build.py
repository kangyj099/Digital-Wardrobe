#!/usr/bin/env python3
"""Assemble the slide deck from `_shell.html` + `parts/*` and inline the images.

Usage:
    python docs/portfolio/build.py                        # full deck
    python docs/portfolio/build.py --parts 10-ai-workflow # one section, for fast iteration
    python docs/portfolio/build.py --out some/path.html

`parts/manifest.json` is the running order. Each entry names a part, which is a
pair of files: `parts/<name>.html` (its <section> blocks) and `parts/<name>.css`
(styles used only by those slides). A part with a `label` becomes one stop on the
bottom indicator; parts without one (cover, closing) carry no indicator.

Slides are numbered from the FULL manifest, never from the subset being written —
so a section built on its own shows the same page numbers it will have in the
final deck, and partial renders stay comparable to the complete one. Parts without
a label are always included so that any build still opens and closes properly.

Three tokens are filled per slide:
    {{PGNO}}  ->  "07 / 14"
    {{NO}}    ->  "07"          (the eyebrow prefix)
    {{IND}}   ->  the indicator, with this slide's part marked active
plus `{{IMG:file.png}}` anywhere, which becomes a base64 data URI so the output
is a single self-contained file.
"""
from __future__ import annotations

import argparse
import base64
import json
import mimetypes
import re
import sys
from pathlib import Path

# part names and labels are Korean; the default Windows console codepage is not
if sys.stdout.encoding and sys.stdout.encoding.lower() not in ("utf-8", "utf8"):
    sys.stdout.reconfigure(encoding="utf-8", errors="replace")

ROOT = Path(__file__).resolve().parent
ASSETS = ROOT / "assets"
PARTS = ROOT / "parts"
IMG_TOKEN = re.compile(r"\{\{IMG:([^}]+)\}\}")
SECTION = re.compile(r"(?=<!-- =+\n     SLIDE )")


def data_uri(name: str) -> str:
    path = ASSETS / name
    if not path.exists():
        raise SystemExit(f"missing asset: {path}")
    mime = mimetypes.guess_type(path.name)[0] or "application/octet-stream"
    return f"data:{mime};base64,{base64.b64encode(path.read_bytes()).decode('ascii')}"


def indicator(labels: list[str], active: str | None) -> str:
    """The frosted category strip. Empty for parts that declare no label."""
    if not labels or active is None:
        return ""
    cells = [
        f'<span class="cat{" on" if l == active else ""}"><i></i>{l}</span>'
        for l in labels
    ]
    inner = '<span class="ln"></span>\n        '.join(cells)
    return f'<div class="ind">\n        {inner}\n    </div>'


def toc(sections: list[dict]) -> str:
    """The cover's contents list. Generated so reordering parts can't leave it
    disagreeing with the deck it introduces."""
    rows = [
        f'<div><i>{i:02d}</i><b>{e["label"]}</b><s>{e.get("summary", "")}</s></div>'
        for i, e in enumerate(sections, start=1)
    ]
    return "\n            ".join(rows)


def categories(labels: list[str]) -> str:
    """The closing slide's part list — same source as the indicator."""
    return "\n            ".join(f"<span>{l}</span>" for l in labels)


def load_manifest() -> list[dict]:
    entries = json.loads((PARTS / "manifest.json").read_text(encoding="utf-8"))
    for e in entries:
        for ext in ("html", "css"):
            if not (PARTS / f"{e['file']}.{ext}").exists():
                raise SystemExit(f"missing part file: parts/{e['file']}.{ext}")
    return entries


def split_sections(html: str) -> list[str]:
    return [c.rstrip() + "\n" for c in SECTION.split(html) if c.strip()]


def build(selected: set[str] | None, dest: Path) -> None:
    manifest = load_manifest()
    sections = [e for e in manifest if e.get("label")]
    labels = [e["label"] for e in sections]

    # number every slide against the whole deck, then keep only what was asked for
    numbered: list[tuple[dict, str]] = []
    for entry in manifest:
        for sec in split_sections((PARTS / f"{entry['file']}.html").read_text(encoding="utf-8")):
            numbered.append((entry, sec))
    total = len(numbered)

    keep = [e["file"] for e in manifest
            if selected is None or e["file"] in selected or not e.get("label")]

    out_sections: list[str] = []
    for i, (entry, sec) in enumerate(numbered, start=1):
        if entry["file"] not in keep:
            continue
        sec = (sec.replace("{{PGNO}}", f"{i:02d} / {total:02d}")
                  .replace("{{NO}}", f"{i:02d}")
                  .replace("{{IND}}", indicator(labels, entry.get("label")))
                  .replace("{{TOC}}", toc(sections))
                  .replace("{{CATS}}", categories(labels)))
        if not out_sections:
            sec = sec.replace('<section class="slide"', '<section class="slide active"', 1)
        out_sections.append(sec)

    part_css = "\n".join(
        (PARTS / f"{e['file']}.css").read_text(encoding="utf-8")
        for e in manifest if e["file"] in keep
    )

    used: list[str] = []

    def sub(match: re.Match[str]) -> str:
        used.append(match.group(1).strip())
        return data_uri(used[-1])

    html = (ROOT / "_shell.html").read_text(encoding="utf-8")
    html = html.replace("{{PART_CSS}}", part_css).replace("{{SLIDES}}", "\n".join(out_sections))
    dest.write_text(IMG_TOKEN.sub(sub, html), encoding="utf-8")

    scope = "full deck" if selected is None else f"parts: {', '.join(sorted(selected))}"
    print(f"built {dest}  ({dest.stat().st_size / 1024:.0f} KB)")
    print(f"  {len(out_sections)} of {total} slides — {scope}")
    for name in sorted(set(used)):
        print(f"  inlined {name} x{used.count(name)}")


if __name__ == "__main__":
    ap = argparse.ArgumentParser()
    ap.add_argument("--parts", help="comma-separated part names to output")
    ap.add_argument("--out", type=Path, help="destination html")
    args = ap.parse_args()

    picked = set(args.parts.split(",")) if args.parts else None
    if picked:
        known = {e["file"] for e in load_manifest()}
        unknown = picked - known
        if unknown:
            raise SystemExit(f"unknown part(s): {', '.join(sorted(unknown))}\nknown: {', '.join(sorted(known))}")

    default = ROOT / (f"portfolio-slides.{'-'.join(sorted(picked))}.html" if picked
                      else "portfolio-slides.html")
    build(picked, args.out or default)
