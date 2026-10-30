---
name: terse-mode
description: Write notes, step results, and agent-to-agent comments in short caveman style to save tokens, and compress memory files. Use it for mem.py notes and results, checkpoint and handoff comments, and when a memory file or AGENTS.md grows too large. Not for Human-facing text, requirements, code, or commits.
---

# terse-mode

Based on the caveman skill (JuliusBrussee/caveman): same meaning, fewer tokens. It only shortens what you write. It does not change how you think or what you check.

## Style: lite (default)

- Drop filler, hedging, pleasantries: "I think maybe", "let me", "certainly", "please note".
- Fragments are fine. Short words. Keep numbers, names, paths, issue numbers exact.
- Pattern: `[thing] [action] [reason]. [next step].`
- Level `full`: also drop articles. Level `ultra`: abbreviate (fn, req, cfg), use arrows. Use `full` only for notes to yourself.

Example: "I looked at the parser and it seems that it does not check for empty input" becomes "Parser: no empty-input check. Add guard + test."

## Use it for

`mem.py note`, `mem.py done` results, checkpoint comments, comments to the Coordinator or Worker, search results you keep.

## Write normally (never terse) for

- Anything the Human must read: escalation questions, final results they asked for.
- Requirements, wiki documents, ADRs, UI specs, ASD-STE100 text.
- Code, comments in code, commit messages, error messages (quote exactly), safety warnings.
- Any text where a short form could be read two ways. Clarity beats size.

## Compress memory files

```bash
python3 $RUST_AGENT_INFRA_DIR/harness/base-skills/terse-mode/scripts/terse_lint.py AGENTS.md --max-tokens 1200
```

If a file is above its limit and it is a note or memory file (not code or requirements), run `/caveman-compress <file>` if the caveman skill is installed. Otherwise rewrite it yourself in lite style and keep a copy as `<file>.orig`. Check that facts, paths, and numbers did not change.

Install the full skill: copy `skills/caveman/SKILL.md` from github.com/JuliusBrussee/caveman to `.kilo/skills/caveman/`. This skill works without it.
