---
name: role-loader
description: Load the role file named by the Role line of an issue, size-capped. Use when the Worker starts an issue.
---

# role-loader

One Worker agent can be an Analyzer, Researcher, Architect, Developer, Designer, Reviewer, Tester, or Qa. The Coordinator picks the role per issue, and the role file tells the Worker how to behave and which skills to use. Loading it first keeps the Worker from mixing responsibilities.

## Procedure

1. Load the role of the issue:

```bash
python3 $RUST_AGENT_INFRA_DIR/harness/worker-skills/role-loader/scripts/load_role.py --issue <n>
```

The script finds the first `Role: <name>` line in the issue body (or a `role:<name>` label) and prints the matching file from `$RUST_AGENT_INFRA_DIR/harness/library/roles`.

2. Read the whole role file and follow it for this issue only. Load the skills the role file names from `$RUST_AGENT_INFRA_DIR/harness/library/skills`.
3. If the script fails, do not pick a role yourself:
   - No role found: comment on the issue, set `status:blocked`, and return it to the Coordinator (`gitea-assignment-handoff`).
   - Role file missing: same, and name the missing role in the comment.
4. After the issue, drop the role. The next issue may need another one (`worker-reset` clears the context).

## Role files

Role files are plain markdown, `<role>.md` or `<role>/ROLE.md`, with the role name matched case-insensitively. Set `ROLES_DIR` only if the library is somewhere else.
