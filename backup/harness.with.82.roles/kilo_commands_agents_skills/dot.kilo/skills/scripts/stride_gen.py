#!/usr/bin/env python3
# stride_gen.py - `stride_gen.py` generates a STRIDE table per component from the architecture model and opens mitigation issues
# STATUS: scaffold. Implement the logic, then remove the not_implemented result.
import json, sys


def main(argv):
    dry = "--dry-run" in argv
    args = [a for a in argv if a != "--dry-run"]
    print(json.dumps({"script": "stride_gen.py", "status": "not_implemented", "dry_run": dry, "args": args,
                      "note": "scaffold - implement this script before relying on it"}))
    return 3


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
