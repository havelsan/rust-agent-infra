#!/usr/bin/env python3
"""Check named crates against the all-time download threshold (default 10000).

Usage: check_crates.py serde tokio some-tiny-crate
Exit code 1 if any crate fails or is not found.
"""
import argparse
import json
import os
import sys
import urllib.error
import urllib.request

p = argparse.ArgumentParser(description=__doc__)
p.add_argument("crates", nargs="+")
p.add_argument("--min-downloads", type=int, default=int(os.environ.get("MIN_CRATE_DOWNLOADS", "10000")))
a = p.parse_args()

bad = 0
for name in a.crates:
    req = urllib.request.Request(f"https://crates.io/api/v1/crates/{name}",
                                 headers={"User-Agent": "agentic-team-crate-filter (contact: project maintainer)"})
    try:
        with urllib.request.urlopen(req, timeout=30) as r:
            c = json.load(r)["crate"]
    except urllib.error.HTTPError as e:
        print(f"NOTFOUND {name} (HTTP {e.code})")
        bad += 1
        continue
    except urllib.error.URLError as e:
        sys.exit(f"error: cannot reach crates.io: {e}")
    ok = c["downloads"] >= a.min_downloads
    print(f"{'PASS' if ok else 'FAIL'}     {name} {c.get('max_stable_version') or c['max_version']} downloads={c['downloads']}")
    bad += 0 if ok else 1
sys.exit(1 if bad else 0)
