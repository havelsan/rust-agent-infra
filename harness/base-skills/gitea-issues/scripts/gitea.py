#!/usr/bin/env python3
"""gitea.py - small Gitea issue CLI for agents (standard library only).

Environment:
  GITEA_URL, GITEA_OWNER, GITEA_REPO, GITEA_ACCESS_TOKEN
"""
import argparse
import json
import os
import signal
import sys
import urllib.error
import urllib.parse
import urllib.request

STATUS_LABELS = {
    "status:todo": "c5def5",
    "status:in-progress": "fbca04",
    "status:blocked": "d93f0b",
    "status:done": "0e8a16",
}
ROLES = ["Analyzer", "Researcher", "Architect", "Developer",
         "Designer", "Reviewer", "Tester", "Qa"]


signal.signal(signal.SIGPIPE, signal.SIG_DFL)


class ApiError(Exception):
    def __init__(self, code, message):
        super().__init__(message)
        self.code = code


def cfg(name):
    value = os.environ.get(name)
    if not value:
        sys.exit(f"error: environment variable {name} is not set")
    return value


def repo():
    return f"/repos/{cfg('GITEA_OWNER')}/{cfg('GITEA_REPO')}"


def api(method, path, body=None, params=None):
    url = cfg("GITEA_URL").rstrip("/") + "/api/v1" + path
    if params:
        url += "?" + urllib.parse.urlencode(params, doseq=True)
    data = json.dumps(body).encode() if body is not None else None
    req = urllib.request.Request(url, data=data, method=method)
    req.add_header("Authorization", "token " + cfg("GITEA_ACCESS_TOKEN"))
    req.add_header("Accept", "application/json")
    if data is not None:
        req.add_header("Content-Type", "application/json")
    try:
        with urllib.request.urlopen(req, timeout=30) as resp:
            raw = resp.read()
            return json.loads(raw) if raw else None
    except urllib.error.HTTPError as err:
        text = err.read().decode(errors="replace")[:500]
        raise ApiError(err.code, f"{method} {path} -> HTTP {err.code}: {text}")
    except urllib.error.URLError as err:
        raise ApiError(0, f"cannot reach Gitea: {err.reason}")


def paged(path, params=None, limit=50):
    out, page = [], 1
    while True:
        q = dict(params or {}, page=page, limit=limit)
        chunk = api("GET", path, params=q) or []
        out.extend(chunk)
        if len(chunk) < limit:
            return out
        page += 1


def label_ids(names):
    """Map label names to ids; create status:/role: labels when missing."""
    existing = {l["name"]: l["id"] for l in paged(f"{repo()}/labels")}
    ids = []
    for name in names:
        if name not in existing:
            if name in STATUS_LABELS:
                color = STATUS_LABELS[name]
            elif name.startswith("role:"):
                color = "5319e7"
            else:
                raise SystemExit(f"error: unknown label '{name}'. Known: {sorted(existing)}")
            existing[name] = api("POST", f"{repo()}/labels", {"name": name, "color": "#" + color})["id"]
        ids.append(existing[name])
    return ids


def read_body(args):
    if getattr(args, "body_file", None):
        if args.body_file == "-":
            return sys.stdin.read()
        with open(args.body_file, encoding="utf-8") as fh:
            return fh.read()
    return args.body or ""


def usernames(issue):
    names = [a["login"] for a in (issue.get("assignees") or [])]
    if issue.get("assignee"):
        names.append(issue["assignee"]["login"])
    return sorted(set(names))


def label_names(issue):
    return [l["name"] for l in issue.get("labels") or []]


def cmd_whoami(a):
    print(api("GET", "/user")["login"])


def cmd_list(a):
    params = {"state": a.state, "type": "issues"}
    if a.label:
        params["labels"] = ",".join(a.label)
    issues = paged(f"{repo()}/issues", params)
    if a.assignee:
        issues = [i for i in issues if a.assignee in usernames(i)]
    issues.sort(key=lambda i: i["number"])
    if a.json:
        print(json.dumps(issues, indent=2))
        return
    for i in issues:
        print(f"#{i['number']} [{i['state']}] ({','.join(usernames(i)) or '-'}) "
              f"{','.join(label_names(i)) or '-'} | {i['title']}")


def cmd_get(a):
    issue = api("GET", f"{repo()}/issues/{a.number}")
    if a.brief:
        import re
        comments = paged(f"{repo()}/issues/{a.number}/comments")
        print(f"#{issue['number']} [{issue['state']}] {issue['title']}")
        print(f"assignees: {','.join(usernames(issue)) or '-'} | labels: {','.join(label_names(issue)) or '-'}")
        body = (issue.get("body") or "").strip()
        print("BODY:\n" + body[:a.max_chars] + (f"\n[body cut at {a.max_chars} chars]" if len(body) > a.max_chars else ""))
        shown = comments[-a.last:] if a.last else []
        if len(comments) > len(shown):
            print(f"({len(comments) - len(shown)} older comment(s) not shown; use --last N)")
        for c in shown:
            text = re.sub(r"<!-- agent-state: .*? -->", "", c.get("body", ""), flags=re.S).strip()
            print(f"--- {(c.get('user') or {}).get('login', '?')} {(c.get('created_at') or '')[:16]}\n{text[:700]}" + (" [cut]" if len(text) > 700 else ""))
        return
    if a.comments:
        issue["comments_list"] = paged(f"{repo()}/issues/{a.number}/comments")
    print(json.dumps(issue, indent=2))


def cmd_create(a):
    body = {"title": a.title, "body": read_body(a)}
    if a.assignee:
        body["assignees"] = a.assignee
    if a.label:
        body["labels"] = label_ids(a.label)
    issue = api("POST", f"{repo()}/issues", body)
    print(issue["number"])


def cmd_comment(a):
    api("POST", f"{repo()}/issues/{a.number}/comments", {"body": read_body(a)})
    print(f"commented on #{a.number}")


def cmd_assign(a):
    api("PATCH", f"{repo()}/issues/{a.number}", {"assignees": a.users})
    print(f"#{a.number} assigned to {','.join(a.users)}")


def cmd_state(a):
    api("PATCH", f"{repo()}/issues/{a.number}", {"state": a.value})
    print(f"#{a.number} is now {a.value}")


def cmd_labels(a):
    issue = api("GET", f"{repo()}/issues/{a.number}")
    names = label_names(issue)
    if a.set is not None:
        names = [n for n in a.set.split(",") if n]
    for n in a.add or []:
        if n not in names:
            names.append(n)
    names = [n for n in names if n not in (a.remove or [])]
    api("PUT", f"{repo()}/issues/{a.number}/labels", {"labels": label_ids(names)})
    print(f"#{a.number} labels: {','.join(names) or '-'}")


def cmd_status(a):
    want = "status:" + a.value
    issue = api("GET", f"{repo()}/issues/{a.number}")
    keep = [n for n in label_names(issue) if not n.startswith("status:")]
    api("PUT", f"{repo()}/issues/{a.number}/labels", {"labels": label_ids(keep + [want])})
    print(f"#{a.number} {want}")


def cmd_ensure_labels(a):
    wanted = list(STATUS_LABELS) + ["role:" + r.lower() for r in ROLES]
    label_ids(wanted)
    print("labels ready: " + ", ".join(wanted))


def build_parser():
    p = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    sub = p.add_subparsers(dest="cmd", required=True)

    sub.add_parser("whoami").set_defaults(fn=cmd_whoami)

    s = sub.add_parser("list")
    s.add_argument("--state", default="open", choices=["open", "closed", "all"])
    s.add_argument("--assignee")
    s.add_argument("--label", action="append")
    s.add_argument("--json", action="store_true")
    s.set_defaults(fn=cmd_list)

    s = sub.add_parser("get")
    s.add_argument("number", type=int)
    s.add_argument("--comments", action="store_true", help="full JSON with all comments (large)")
    s.add_argument("--brief", action="store_true", help="compact text: body + last comments (use this by default)")
    s.add_argument("--max-chars", type=int, default=3000, help="body limit for --brief")
    s.add_argument("--last", type=int, default=5, help="number of recent comments for --brief")
    s.set_defaults(fn=cmd_get)

    s = sub.add_parser("create")
    s.add_argument("--title", required=True)
    s.add_argument("--body")
    s.add_argument("--body-file")
    s.add_argument("--assignee", action="append")
    s.add_argument("--label", action="append")
    s.set_defaults(fn=cmd_create)

    s = sub.add_parser("comment")
    s.add_argument("number", type=int)
    s.add_argument("--body")
    s.add_argument("--body-file", help="path, or - for stdin")
    s.set_defaults(fn=cmd_comment)

    s = sub.add_parser("assign")
    s.add_argument("number", type=int)
    s.add_argument("users", nargs="+")
    s.set_defaults(fn=cmd_assign)

    s = sub.add_parser("state")
    s.add_argument("number", type=int)
    s.add_argument("value", choices=["open", "closed"])
    s.set_defaults(fn=cmd_state)

    s = sub.add_parser("labels")
    s.add_argument("number", type=int)
    s.add_argument("--set")
    s.add_argument("--add", action="append")
    s.add_argument("--remove", action="append")
    s.set_defaults(fn=cmd_labels)

    s = sub.add_parser("status")
    s.add_argument("number", type=int)
    s.add_argument("value", choices=["todo", "in-progress", "blocked", "done"])
    s.set_defaults(fn=cmd_status)

    sub.add_parser("ensure-labels").set_defaults(fn=cmd_ensure_labels)
    return p


def main():
    args = build_parser().parse_args()
    try:
        args.fn(args)
    except ApiError as err:
        sys.exit(f"error: {err}")


if __name__ == "__main__":
    main()
