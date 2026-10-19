#!/usr/bin/env python3
# model_spec_lint.py - `model_spec_lint.py` checks that the spec defines all symbols, units and boundary conditions
# STATUS: scaffold. Implement the logic, then remove the not_implemented result.
import json, sys


def main(argv):
    dry = "--dry-run" in argv
    args = [a for a in argv if a != "--dry-run"]
    print(json.dumps({"script": "model_spec_lint.py", "status": "not_implemented", "dry_run": dry, "args": args,
                      "note": "scaffold - implement this script before relying on it"}))
    return 3


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
