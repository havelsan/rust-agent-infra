---
name: role-selection
description: Choose the Worker role for an issue and write the Role line. Use when creating or reassigning a Worker issue or when the role is unclear.
---

# role-selection

The Worker loads exactly one role from `$RUST_AGENT_INFRA_DIR/harness/library/roles` based on the issue. A missing or wrong role wastes a whole Worker session, so name it explicitly.

## Role guide

| Role | Pick it when the issue asks to... |
| --- | --- |
| Analyzer | check an issue or document for ambiguity, contradiction, completeness, STE100 compliance; build the requirements wiki |
| Researcher | find a Rust crate or framework for a stated need |
| Architect | design or check structure, layers, boundaries, decision records |
| Developer | write or change Rust code |
| Designer | design a UX flow or UI screen |
| Reviewer | review Rust code |
| Tester | write Rust tests |
| Qa | run final checks and build the `.rpm` and `.deb` packages |

## Procedure

1. Run the helper for a first suggestion:

```bash
python3 $RUST_AGENT_INFRA_DIR/harness/coordinator-skills/role-selection/scripts/select_role.py "Implement the parser for requirement REQ-4"
```

2. Confirm by reading the task. The script counts keywords only. "Test the parser design" is Architect or Reviewer work, not Tester work.
3. If two roles fit, split the task into two issues. One issue, one role.
4. Write the role as the first line of the issue body, exactly:

```
Role: Developer
```

The `role-loader` skill reads this line. Add the `role:developer` label if you want to filter by role.

## Special cases

- Architecture status checks that the Coordinator runs periodically: use `architecture-checkpoint`.
- A task about the roles or skills themselves: ask the Human.
