#!/usr/bin/env python3
# handoff.py - post a structured hand-off comment on a Gitea issue and set the next-role label.
# Usage: handoff.py --issue N --from-role N --to-role N --status done|blocked|needs-review|needs-input
#                   [--artifact PATH ...] [--summary TEXT] [--questions TEXT] [--dry-run]
import argparse, json, os, sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import _gitea


def main(argv):
    p = argparse.ArgumentParser(prog="handoff.py")
    p.add_argument("--issue", type=int, required=True)
    p.add_argument("--from-role", type=int, required=True)
    p.add_argument("--to-role", type=int, required=True)
    p.add_argument("--status", choices=["done", "blocked", "needs-review", "needs-input"], required=True)
    p.add_argument("--artifact", action="append", default=[])
    p.add_argument("--summary", default="")
    p.add_argument("--questions", default="")
    p.add_argument("--dry-run", action="store_true")
    a = p.parse_args(argv)
    missing = [x for x in a.artifact if not os.path.exists(x)]
    if missing:
        print(json.dumps({"script": "handoff.py", "status": "fail", "detail": "missing artifacts", "missing": missing}))
        return 1
    lines = [f"### Hand-off: role {a.from_role} -> role {a.to_role}", f"**Status:** {a.status}", ""]
    if a.summary:
        lines += ["**Summary:** " + a.summary, ""]
    lines.append("**Artifacts:**")
    lines += [f"- `{x}`" for x in a.artifact] or ["- (none)"]
    if a.questions:
        lines += ["", "**Open questions:** " + a.questions]
    body = "\n".join(lines)
    _gitea.DRY = a.dry_run
    try:
        _gitea.api("POST", f"/issues/{a.issue}/comments", {"body": body})
        _gitea.api("POST", f"/issues/{a.issue}/labels",
                   {"labels": _gitea.label_ids([f"role:{a.to_role}", f"handoff:{a.status}"])})
    except _gitea.GiteaError as e:
        print(json.dumps({"script": "handoff.py", "status": "fail", "detail": str(e)}))
        return 1
    print(json.dumps({"script": "handoff.py", "status": "dry-run" if a.dry_run else "pass", "issue": a.issue}))
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
