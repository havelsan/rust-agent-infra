---
name: lean-shell
description: Run shell commands with small output using rtk (Rust Token Killer), with a safe fallback. Use it for every command that can print more than about 30 lines - git, cargo build, test, clippy, grep, find, ls - and when reading files.
---

# lean-shell

Raw command output is the biggest waste of a small context. `rtk` filters it (cargo test shows failures only, git status is compact). The wrapper uses rtk when the right one is installed and cuts long output when it is not.

```bash
RT=$RUST_AGENT_INFRA_DIR/harness/base-skills/lean-shell/scripts/rt.sh
$RT cargo test          # failures only
$RT cargo clippy
$RT git status          # also: git diff, git log -5
$RT grep "fn parse" src/
$RT find "*.rs" .
$RT read src/lib.rs     # first 6000 chars, compact
```

## Rules

- Prefix with `rt.sh` any command that may print more than 30 lines. Short commands run directly.
- Never `cat` a file above 6000 chars. Use `rt.sh read` or `mem.py slice <file> <part>`.
- Ask for less before asking for more: `grep -n` before opening, `git diff --stat` before `git diff`.
- A cut line `[... N lines cut ...]` means you saw the start and the end. For a failure, search the cause with `grep` instead of printing all.
- The exit code is passed through, so you can trust it.
- Check tools once per session: `check_tools.sh` (all four tools are optional).

## Notes

- `rtk gain` proves the correct tool (a different crate is also named rtk).
- Install: `curl -fsSL https://raw.githubusercontent.com/rtk-ai/rtk/refs/heads/master/install.sh | sh`.
