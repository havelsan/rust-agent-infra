---
description: "[AI / ML] AI feature with tool orchestration and prompt evaluation"
agent: team-leader
---
Run `kctx run add-ai-feature $ARGUMENTS` in the shell and report only its short JSON result. Do not load other files.
Signature: /add-ai-feature <feature> [--llm <provider>] [--tools <list>] [--eval-set]
Chain: @ai-engineer -> @software-architect -> @security-engineer -> @software-quality-assurance-engineer
Output: AI feature with tool orchestration and prompt evaluation. Default gates: review, QA, security.
