---
name: agent-memory
description: Layered memory for a small context window - plan, step results, and notes saved outside the context, checkpointed to the Gitea issue, and restored after /reset. Use it at the start of every issue, after every step, when context is above 60 percent, and when resuming an interrupted issue.
---

# agent-memory

Context is small. Keep only the current step in it. Everything else lives in a lower level and comes back on demand.

| Level | Where | Holds | Read with |
| --- | --- | --- | --- |
| L0 | context | current step only | - |
| L1 | `.mem/<issue>/` | plan, step results, notes. Survives `/reset` | `mem.py recall` |
| L2 | issue comment (checkpoint) | copy of L1. Survives lost workspace; lets another agent resume | `mem.py start` restores it |
| L3 | wiki + graphify graph | requirements, ADRs, code map | `gitea-wiki`, `graph-memory` |
| L4 | roles, skills, `PRINCIPLES.md` | rules | `mem.py slice`, grep. Never load whole |

```bash
M="python3 $RUST_AGENT_INFRA_DIR/harness/base-skills/agent-memory/scripts/mem.py"
$M start 12 --goal "one line"      # new, or restored from the last checkpoint
$M plan 12 "step 1" "step 2"       # max 8 steps, 160 chars each
$M next 12 ; $M done 12 "result"   # one step at a time, result max 240 chars
$M fail 12 "why"                   # 2nd failure tells you to split
$M split 12 3 "3a" "3b"            # 2-4 smaller steps
$M note 12 "fact to keep"          # max 300 chars, newest 3000 chars kept
$M recall 12                       # compact state, use instead of re-reading
$M checkpoint 12                   # L2: post state to the issue
$M budget AGENTS.md --used 18000   # tokens used so far, from the UI
$M slice big.md 2                  # read part 2 of a large file
$M clear 12                        # after issue-completion
```

## When to checkpoint

- Every 3 finished steps, and before any risky step.
- Context at 60 percent: finish the step, then checkpoint.
- Context at 75 percent: checkpoint now, run `/reset`, then `mem.py start <issue>`.

## Rules

- Write results as facts, not stories. Keep long text in files or the wiki and store the path.
- After a reset, trust `recall`. Do not re-read finished work.
- `MEM_CONTEXT_TOKENS` sets the window size (default 32000).
