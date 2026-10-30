---
name: step-protocol
description: Split every task into think, plan, execute small steps, and split again when a step fails or is too big. Use it for every issue and every task that cannot be finished in one short attempt, in any role.
---

# step-protocol

A small context cannot hold a whole task. Work in short loops and save after each one.

## Loop

1. **THINK** (max 100 words): goal, inputs, unknowns, risks. Save with `mem.py note`. Read only what you need, using `slice` and `graph-memory`.
2. **PLAN**: `mem.py plan <n> "step"...` with 1 to 8 steps. A good step:
   - changes or checks one thing (one file, one requirement batch, one crate),
   - needs about 4K tokens of reading and writing or less,
   - has a visible "done when" in its text (a test passes, a page exists).
3. **EXECUTE**: `mem.py next <n>`, do only that step, then `mem.py done <n> "result"`.
4. **CHECK**: after each step look at the context level (`mem.py budget --used N`). Follow `agent-memory` for checkpoint and reset.

## When a step does not finish

| Sign | Action |
| --- | --- |
| Step fails once | Retry once with a smaller change |
| Step fails twice (`mem.py fail` says SPLIT) | `mem.py split` into 2 to 4 sub-steps |
| Needs more than 3 files, or output over 150 lines | Split before you start |
| Missing information | Stop. Return the issue as `blocked` with one clear question |
| Split twice and still too big | Return `blocked`. Ask the Coordinator to re-scope into new issues |

## Rules

- One step in your head at a time. Do not plan details of step 5 while doing step 2.
- Do not start the next step before `done` is recorded.
- Never retry the same failed action unchanged.
- Say what you did not do. An honest partial result is better than a claimed full one.
- Each role skill lists its own natural split points in "Steps".
