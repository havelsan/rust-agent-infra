---
description: "[Standards] Part-by-part summary file with a quick reference (default summaries/<pdf name>.md)"
agent: team-leader
---
Run `kctx run summarize-book $ARGUMENTS` in the shell and report only its short JSON result. Do not load other files.
Signature: /summarize-book <pdf> [--out <file>] [--force]
Chain: @team-leader
Output: Part-by-part summary file with a quick reference (default summaries/<pdf name>.md). Default gates: review, QA, security.
