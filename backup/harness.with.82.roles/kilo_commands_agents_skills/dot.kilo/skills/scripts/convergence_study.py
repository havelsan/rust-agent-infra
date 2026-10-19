#!/usr/bin/env python3
# convergence_study.py - `convergence_study.py` runs refinement series and fits the observed convergence order
# STATUS: scaffold. Implement the logic, then remove the not_implemented result.
import json, sys


def main(argv):
    dry = "--dry-run" in argv
    args = [a for a in argv if a != "--dry-run"]
    print(json.dumps({"script": "convergence_study.py", "status": "not_implemented", "dry_run": dry, "args": args,
                      "note": "scaffold - implement this script before relying on it"}))
    return 3


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
