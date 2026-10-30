---
name: gitea-wiki
description: List, read, create, and update project-01 Gitea wiki pages with the gitea-mcp tools. Use to store or look up requirements, architecture pages, ADRs, specs, and status reports.
---

# gitea-wiki

The wiki holds long-lived project knowledge. Issues hold conversations and tasks. A result that other roles need later goes in the wiki, and the issue comment links to it.

## Tools (gitea-mcp)

Every call needs `owner` and `repo` (see `gitea-issues`).

| Need | Tool | Key arguments |
| --- | --- | --- |
| List pages | `wiki_read` `method=list` | |
| Read | `wiki_read` `method=get` | `page_name="Requirements-Index"` |
| Create | `wiki_write` `method=create` | `title="Requirements Index"`, `content`, `message` |
| Update | `wiki_write` `method=update` | `page_name`, `content`, `message` |

`content` is plain markdown text. Do not base64 it. A page name uses dashes for spaces (`Requirements-Index`).

## Rules

- There is no slicing. `get` returns the whole page into your context. Keep each page under about 5000 characters. Split bigger content into linked pages (`Name`, `Name 2`) with an index page.
- Create or update: check `wiki_read list` first. Create when the page is missing, update when it exists.
- `update` replaces the whole page. Read the current page (`get`) and merge first. An update built from memory deletes other agents' text.
- Start every page with a one-line purpose. Keep a `Related issues` list at the bottom (`#12`, `#15`).
- Link pages with Gitea wiki links: `[[Architecture Overview]]`.
- After writing, mention the page name in the issue comment.
- Long text you built in a file: read it with `rt.sh read` or `mem.py slice`, then pass it as `content`. The text passes through your context twice, so prefer short pages.
