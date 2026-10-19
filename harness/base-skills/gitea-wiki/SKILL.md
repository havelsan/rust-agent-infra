---
name: gitea-wiki
description: List, read (in slices), create, and update project-01 Gitea wiki pages. Use to store or look up requirements, architecture pages, ADRs, specs, and status reports.
---

# gitea-wiki

The wiki holds long-lived project knowledge. Issues hold conversations and tasks. Keep this split: a result that other roles need later goes in the wiki, and the issue comment links to it.

## Commands

```bash
W="python3 $RUST_AGENT_INFRA_DIR/harness/base-skills/gitea-wiki/scripts/wiki.py"
$W list
$W get "Requirements Index"
$W put "Requirements Index" --file page.md --message "add REQ-12"   # creates or updates
```

The script uses the same environment variables as `gitea-issues`.

## Rules

- Page names use words separated by spaces or dashes: `Architecture Overview`, `ADR-003-Message-Bus`. Gitea stores spaces as dashes.
- Read the current page before updating it (`get`) and merge. `put` replaces the whole page, so an update built from memory deletes other agents' text.
- Start every page with a one-line purpose and keep a `Related issues` list at the bottom (`#12`, `#15`) so readers can trace decisions.
- Link pages with Gitea wiki links: `[[Architecture Overview]]`.
- After writing, mention the page name in the issue comment.
