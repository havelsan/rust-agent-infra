---
name: worker-reset
description: Run clear_worker.sh, then /reset and /reload so the next issue starts clean. Use only after issue-completion, and only when the agent runs as its own session (not as a subagent).
---

# worker-reset

Each issue should start with a clean workspace and an empty context. Leftover files, loaded roles, and old reasoning from the previous issue cause wrong assumptions in the next one.

## Order matters

Run this only after `issue-completion`, and only when the agent runs as its own session. A subagent called with `task` starts with a fresh context each time. It returns one line and does not reset.

Run this only after `issue-completion`. The reset removes everything that is not saved in the repository, wiki, or issue.

1. Check that the completion comment is posted and that the work is committed or saved.
2. Run the cleanup:

```bash
$RUST_AGENT_INFRA_DIR/harness/worker-skills/worker-reset/scripts/reset_worker.sh
```

This calls `$RUST_AGENT_INFRA_DIR/harness/clear_worker.sh`.

3. Run the agent command `/reset`.
4. Run the agent command `/reload`. It reloads the skills and configuration, including the `.kilo/skills` links.
5. Go back to `issue-polling`.

`/reset` and `/reload` are commands of the agent, not shell commands, so the script only reminds you to run them.
