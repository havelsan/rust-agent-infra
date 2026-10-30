#!/usr/bin/env python3
"""wiki.py - read and write Gitea wiki pages of the project repository.

Uses the same environment as gitea.py (GITEA_URL, GITEA_OWNER, GITEA_REPO, GITEA_ACCESS_TOKEN).
"""
import argparse
import base64
import os
import signal
import sys
from pathlib import Path

here = Path(__file__).resolve()
candidates = [here.parents[2] / "gitea-issues" / "scripts"]
if os.environ.get("RUST_AGENT_INFRA_DIR"):
    candidates.append(Path(os.environ["RUST_AGENT_INFRA_DIR"]) / "harness/base-skills/gitea-issues/scripts")
for c in candidates:
    if (c / "gitea.py").exists():
        sys.path.insert(0, str(c))
        break
import gitea  # noqa: E402


signal.signal(signal.SIGPIPE, signal.SIG_DFL)


def page_name(title):
    return title.strip().replace(" ", "-")


def cmd_list(a):
    for p in gitea.paged(f"{gitea.repo()}/wiki/pages"):
        print(p.get("title") or p.get("sub_url"))


def cmd_get(a):
    page = gitea.api("GET", f"{gitea.repo()}/wiki/page/{page_name(a.name)}")
    text = base64.b64decode(page["content_base64"]).decode("utf-8")
    if not a.chars or len(text) <= a.chars:
        print(text)
        return
    parts, cur = [], ""
    for line in text.splitlines(keepends=True):
        if len(cur) + len(line) > a.chars and cur:
            parts.append(cur)
            cur = ""
        cur += line
    parts.append(cur)
    if not 1 <= a.part <= len(parts):
        sys.exit(f"error: part must be 1..{len(parts)}")
    print(f"[{a.name} part {a.part}/{len(parts)}; use --part N, or --chars 0 for all]")
    print(parts[a.part - 1])


def cmd_put(a):
    text = sys.stdin.read() if a.file == "-" else Path(a.file).read_text(encoding="utf-8")
    payload = {
        "title": a.name,
        "content_base64": base64.b64encode(text.encode("utf-8")).decode("ascii"),
        "message": a.message,
    }
    name = page_name(a.name)
    try:
        gitea.api("GET", f"{gitea.repo()}/wiki/page/{name}")
        exists = True
    except gitea.ApiError as err:
        if err.code != 404:
            raise
        exists = False
    if exists:
        gitea.api("PATCH", f"{gitea.repo()}/wiki/page/{name}", payload)
        print(f"updated wiki page {name}")
    else:
        gitea.api("POST", f"{gitea.repo()}/wiki/new", payload)
        print(f"created wiki page {name}")


def main():
    p = argparse.ArgumentParser(description=__doc__)
    sub = p.add_subparsers(dest="cmd", required=True)
    sub.add_parser("list").set_defaults(fn=cmd_list)
    s = sub.add_parser("get")
    s.add_argument("name")
    s.add_argument("--part", type=int, default=1)
    s.add_argument("--chars", type=int, default=6000, help="part size; 0 = whole page")
    s.set_defaults(fn=cmd_get)
    s = sub.add_parser("put")
    s.add_argument("name")
    s.add_argument("--file", required=True, help="markdown file, or - for stdin")
    s.add_argument("--message", default="update by agent")
    s.set_defaults(fn=cmd_put)
    args = p.parse_args()
    try:
        args.fn(args)
    except gitea.ApiError as err:
        sys.exit(f"error: {err}")


if __name__ == "__main__":
    main()
