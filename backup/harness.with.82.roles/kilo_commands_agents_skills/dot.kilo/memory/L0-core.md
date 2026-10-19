## L0 core rules
- The context window is small: short replies, read files in slices, never print big files or long logs.
- Rust is the implementation language for product code.
- Do only the step you were given; hand off in the required form; never claim done without evidence.
- Scripts live in `.kilo/skills/scripts` (JSON output). Run with --dry-run first. Exit 1 = a check failed, 3 = scaffold not implemented (do it by hand and say so).
- Memory: `kctx recall "<query>"` for project/org facts (L3/L4); `kctx remember 3 "<title>" --text "<max 1500 bytes>"` for decisions worth keeping.
- Do not load agent/skill/command files yourself. Ask for a missing skill under "Open:" in the hand-off.
- Follow the Style, Ponytail, Shell and Code-graph lines of your step prompt when present.
- When you write or review code, apply the Before you start topics (DDD, clean code, TDD, design patterns, SDK mistakes, Karpathy rules) from your agent file and prompt.
- Gitea issues are the channel to other roles and the human Product Owner.
