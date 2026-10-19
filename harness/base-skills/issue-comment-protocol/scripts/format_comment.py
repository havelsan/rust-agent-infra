#!/usr/bin/env python3
"""Print an issue comment in the standard agent format."""
import argparse
import os

p = argparse.ArgumentParser(description=__doc__)
p.add_argument("--role", required=True, help="role used for the work, e.g. Developer")
p.add_argument("--status", required=True, choices=["done", "blocked", "in-progress", "question"])
p.add_argument("--done", required=True, help="what was done, one or two sentences")
p.add_argument("--result", default="", help="outcome or finding")
p.add_argument("--changed", action="append", default=[], help="file or wiki page changed (repeatable)")
p.add_argument("--next", dest="next_step", default="", help="proposed next step")
p.add_argument("--agent", default=os.environ.get("AGENT_NAME", "agent"))
a = p.parse_args()

lines = [f"**Agent:** {a.agent} | **Role:** {a.role} | **Status:** {a.status}", "",
         "### What was done", a.done, ""]
if a.result:
    lines += ["### Result", a.result, ""]
if a.changed:
    lines += ["### Files / pages changed"] + [f"- {c}" for c in a.changed] + [""]
lines += ["### Next step", a.next_step or "None. Waiting for the Coordinator."]
print("\n".join(lines))
