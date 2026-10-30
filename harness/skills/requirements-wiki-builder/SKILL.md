---
name: requirements-wiki-builder
description: Build and update the requirements index in the wiki from requirement lines. Use when the Coordinator asks the Analyzer to build or refresh the requirements wiki.
---

# requirements-wiki-builder

Later roles (Architect, Developer, Tester, Qa) read requirements from the wiki, not from the long issue threads. A clean index lets them cite `REQ-12` instead of copying text.

## Procedure

1. Collect requirement text from the issues and documents named by the Coordinator. Give each requirement a stable ID (`REQ-001`). Never renumber existing IDs. Keep a removed requirement as `status: withdrawn`.
2. Put the requirements in a working file, one per line:

```
REQ-001: The system shall log every command within 1 s. [status: accepted] [source: #12]
```

3. Run `requirements-quality-check` first. Do not publish contradictory text without marking it.
4. Publish:

```bash
python3 $RUST_AGENT_INFRA_DIR/harness/library/skills/requirements-wiki-builder/scripts/build_requirements_wiki.py reqs.md [--by-prefix] [--max-chars 5000]
```

The script does not touch Gitea. It writes page files to `.mem/wiki-out/` (`Requirements-Index.md`, `Requirements-Index-2.md`, and `Requirements-<PREFIX>.md` with `--by-prefix`) and prints the file names. A page is split when it passes `--max-chars` (`gitea-wiki`: pages stay small).
5. Read the current wiki first (`wiki_read` `get`, page `Requirements-Index`) and merge into the working file. The script builds whole pages, so the working file must contain every existing requirement. Then publish each page file: read it (`rt.sh read`), and call `wiki_write` with `create` (new page) or `update` (existing page, see `wiki_read` `list`).
6. Comment on the issue with the page names and the number of requirements added or changed.

## Status values

`draft`, `accepted`, `implemented`, `verified`, `withdrawn`. The Human sets `accepted`. The Analyzer does not.

## Steps (split points)

Use with `step-protocol`. One step per 20 requirements: collect, quality-check. Last step: merge with the current page and publish.
