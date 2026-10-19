---
name: dependency-and-critical-path-planning
description: "Model task dependencies, find the critical path, and flag schedule risk."
---
Script: `python3 .kilo/skills/scripts/plan_graph.py` (run with --dry-run first). plan_graph.py builds a DAG from issue links, computes the critical path, and outputs a Mermaid Gantt chart
Do: read the issue and the hand-off, apply this skill, save results in the repo, report in the hand-off.
