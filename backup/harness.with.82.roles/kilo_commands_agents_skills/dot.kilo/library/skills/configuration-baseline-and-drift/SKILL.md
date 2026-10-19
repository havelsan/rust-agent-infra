---
name: configuration-baseline-and-drift
description: "Capture configuration baselines and detect drift between environments and versions."
---
Script: `bash .kilo/skills/scripts/baseline_snapshot.sh` (run with --dry-run first). Also: `drift_diff.py`. baseline_snapshot.sh records config and versions; drift_diff.py compares a snapshot against live state
Do: read the issue and the hand-off, apply this skill, save results in the repo, report in the hand-off.
