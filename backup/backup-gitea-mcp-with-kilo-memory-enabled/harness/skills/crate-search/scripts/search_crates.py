#!/usr/bin/env python3
"""Search crates.io and drop crates below the all-time download threshold (default 10000)."""
import argparse
import json
import os
import sys
import urllib.error
import urllib.parse
import urllib.request

p = argparse.ArgumentParser(description=__doc__)
p.add_argument("query")
p.add_argument("--min-downloads", type=int, default=int(os.environ.get("MIN_CRATE_DOWNLOADS", "10000")))
p.add_argument("--sort", default="relevance", choices=["relevance", "downloads", "recent-downloads", "recent-updates"])
p.add_argument("--limit", type=int, default=20)
p.add_argument("--json", action="store_true")
a = p.parse_args()

url = "https://crates.io/api/v1/crates?" + urllib.parse.urlencode(
    {"q": a.query, "per_page": min(a.limit, 100), "sort": a.sort})
req = urllib.request.Request(url, headers={"User-Agent": "agentic-team-crate-search (contact: project maintainer)"})
try:
    with urllib.request.urlopen(req, timeout=30) as r:
        data = json.load(r)
except urllib.error.URLError as e:
    sys.exit(f"error: cannot reach crates.io: {e}")

kept, dropped = [], 0
for c in data.get("crates", []):
    if c.get("downloads", 0) < a.min_downloads:
        dropped += 1
        continue
    kept.append({"name": c["name"], "version": c.get("max_stable_version") or c.get("max_version"),
                 "downloads": c["downloads"], "recent_downloads": c.get("recent_downloads"),
                 "updated_at": c.get("updated_at"), "repository": c.get("repository"),
                 "description": " ".join((c.get("description") or "").split())})
if a.json:
    print(json.dumps(kept, indent=2))
else:
    print("| Crate | Version | Downloads (all time) | Recent | Updated | Description |")
    print("| --- | --- | ---: | ---: | --- | --- |")
    for c in kept:
        print(f"| {c['name']} | {c['version']} | {c['downloads']} | {c['recent_downloads']} | "
              f"{(c['updated_at'] or '')[:10]} | {c['description'][:80].replace('|', '/')} |")
    print(f"\n{len(kept)} kept, {dropped} dropped (fewer than {a.min_downloads} downloads all time)")
