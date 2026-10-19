---
name: ux-ui-design
description: Produce UX flows and UI specs (screens, states, accessibility) as wiki pages. Use for Designer tasks.
---

# ux-ui-design

A Developer who starts with an empty context needs a spec with exact states and texts, not a picture alone. Missing states (empty, loading, error) are the most common source of rework.

## Procedure

1. Read the issue, the requirement IDs, and any earlier pages (`gitea-wiki`). Find who the users are. If the requirements do not say, list it under open questions.
2. Copy `templates/ui-spec.md` and fill every section:
   - **Screens**: purpose, elements, actions.
   - **Flows**: numbered steps from start state to end state, including the error path.
   - **States**: empty, loading, success, error, disabled. Write the exact message text.
   - **Accessibility**: keyboard path, focus order, contrast, labels.
3. Draw structure with text wireframes or a Mermaid diagram in the page. Do not attach tool-specific files that others cannot open.
4. Check the spec:

```bash
python3 $RUST_AGENT_INFRA_DIR/harness/library/skills/ux-ui-design/scripts/check_ui_spec.py ui-spec.md
```

5. Publish it as the wiki page `UI Spec - <name>` (`gitea-wiki put`).
6. Comment on the issue with the page name and the open questions. Questions about product decisions go back to the Coordinator.

## Design rules

- One primary action per screen.
- Use words from the requirements and the domain model. Do not invent new names for existing concepts.
- Show errors next to their cause and say how to fix them.
- Keep the flow short. Remove a step before you design a better one.
- For command-line tools: define commands, options, exit codes, and the exact output format.

## Steps (split points)

Use with `step-protocol`. One screen per step: elements, flow, states, accessibility. Last steps: check script, publish.
