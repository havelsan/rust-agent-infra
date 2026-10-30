---
name: issue-comment-protocol
description: Standard format for every agent comment on an issue - author header, what was done, result, files changed, next step. Use whenever you finish, block, or report on an issue.
---

# issue-comment-protocol

Agents start each task with an empty context, so the issue comment is the only memory that survives. A fixed format lets the next agent (or the Human) find the outcome in seconds.

All agents write through one Gitea account, so the first line names the author. A comment with no `[Agent]` header is from the Human.

## Format

```
[Developer] done

**Role:** Developer | **Status:** done

### What was done
<one or two sentences, past tense>

### Result
<finding, decision, test outcome, or link to the wiki page>

### Files / pages changed
- path/or/wiki-page

### Next step
<what should happen next, and who should do it>
```

First line: `[<Agent>] <event>`. Events: `done`, `blocked`, `question`, `note`, `checkpoint`, `misrouted`. Status: `done`, `blocked`, `in-progress`, or `question`.

Post it with `issue_write` `method=add_comment`, `issue_number`, `body`.

## Writing rules

- Say what happened, not what was planned. Use plain, short sentences. ASD-STE100 style is welcome for requirement text.
- Put long output (logs, full reports) in the wiki or a file and link it. A comment above about 40 lines is hard to read.
- A `blocked` or `question` status must say exactly what is missing and who can supply it.
- Never paste tokens, passwords, or environment dumps.
- Leave out empty sections. For a short `note`, the header line and one or two sentences are enough.
