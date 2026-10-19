#!/usr/bin/env python3
# _gitea.py - minimal Gitea REST client used by gitea_issue.sh and handoff.py
# Env: GITEA_URL (e.g. https://git.example.com), GITEA_TOKEN, GITEA_REPO (owner/repo)
# Pass --dry-run to print the requests instead of sending them.
import argparse, json, os, sys, urllib.error, urllib.request

DRY = False


class GiteaError(Exception):
    pass


def cfg():
    url, token, repo = os.environ.get("GITEA_URL"), os.environ.get("GITEA_TOKEN"), os.environ.get("GITEA_REPO")
    if not (url and token and repo):
        raise GiteaError("set GITEA_URL, GITEA_TOKEN and GITEA_REPO (owner/repo)")
    return url.rstrip("/"), token, repo


def api(method, path, data=None):
    if DRY:
        print(json.dumps({"dry_run": True, "method": method, "path": path, "data": data}))
        return {}
    url, token, repo = cfg()
    body = json.dumps(data).encode() if data is not None else None
    req = urllib.request.Request(
        f"{url}/api/v1/repos/{repo}{path}", data=body, method=method,
        headers={"Authorization": f"token {token}", "Content-Type": "application/json", "Accept": "application/json"})
    try:
        with urllib.request.urlopen(req, timeout=30) as resp:
            raw = resp.read().decode()
            return json.loads(raw) if raw else {}
    except urllib.error.HTTPError as e:
        raise GiteaError(f"HTTP {e.code} on {method} {path}: {e.read().decode()[:500]}")
    except urllib.error.URLError as e:
        raise GiteaError(f"connection error on {method} {path}: {e.reason}")


def label_ids(names):
    names = [n for n in names if n]
    if DRY:
        return names
    if not names:
        return []
    existing = {l["name"]: l["id"] for l in api("GET", "/labels?limit=200")}
    ids = []
    for n in names:
        if n not in existing:
            existing[n] = api("POST", "/labels", {"name": n, "color": "#0e8a16"})["id"]
        ids.append(existing[n])
    return ids


def main(argv):
    global DRY
    if "--dry-run" in argv:
        DRY = True
        argv = [a for a in argv if a != "--dry-run"]
    p = argparse.ArgumentParser(prog="gitea_issue.sh")
    sub = p.add_subparsers(dest="cmd", required=True)
    c = sub.add_parser("create")
    c.add_argument("--title", required=True)
    c.add_argument("--body", default="")
    c.add_argument("--labels", default="")
    c.add_argument("--assignee", default="")
    m = sub.add_parser("comment")
    m.add_argument("issue", type=int)
    m.add_argument("--body", required=True)
    l = sub.add_parser("label")
    l.add_argument("issue", type=int)
    l.add_argument("--add", required=True)
    a = sub.add_parser("assign")
    a.add_argument("issue", type=int)
    a.add_argument("--to", required=True)
    x = sub.add_parser("close")
    x.add_argument("issue", type=int)
    g = sub.add_parser("get")
    g.add_argument("issue", type=int)
    ls = sub.add_parser("list")
    ls.add_argument("--state", default="open")
    ls.add_argument("--labels", default="")
    args = p.parse_args(argv)
    try:
        if args.cmd == "create":
            data = {"title": args.title, "body": args.body, "labels": label_ids(args.labels.split(","))}
            if args.assignee:
                data["assignees"] = [args.assignee]
            res = api("POST", "/issues", data)
        elif args.cmd == "comment":
            res = api("POST", f"/issues/{args.issue}/comments", {"body": args.body})
        elif args.cmd == "label":
            res = api("POST", f"/issues/{args.issue}/labels", {"labels": label_ids(args.add.split(","))})
        elif args.cmd == "assign":
            res = api("PATCH", f"/issues/{args.issue}", {"assignees": [args.to]})
        elif args.cmd == "close":
            res = api("PATCH", f"/issues/{args.issue}", {"state": "closed"})
        elif args.cmd == "get":
            res = api("GET", f"/issues/{args.issue}")
        else:
            q = f"/issues?type=issues&state={args.state}&limit=50"
            if args.labels:
                q += f"&labels={args.labels}"
            res = api("GET", q)
    except GiteaError as e:
        print(json.dumps({"status": "fail", "detail": str(e)}))
        return 1
    if not DRY:
        print(json.dumps(res))
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
