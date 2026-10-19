---
name: command-parsing-dispatch
description: "Validate a command and its parameters against the schema, merge defaults, policy file and overrides, and resolve the role chain."
---
Script: `python3 .kilo/skills/scripts/parse_command.py` (run with --dry-run first). parse_command.py validates args against a JSON schema, merges .agents/policy.toml, and emits the epic YAML
Do: read the issue and the hand-off, apply this skill, save results in the repo, report in the hand-off.
