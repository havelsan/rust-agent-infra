---
name: principles-check
description: Check requirements, designs, or Rust code against PRINCIPLES.md (Musk, SOLID, NASA rules) and COMMON_MISTAKES.md, with a Rust scanner. Use for Analyzer, Architect, Developer, and Reviewer checks.
---

# principles-check

The principles are fixed project rules, kept in `$RUST_DEV_ENV/reference-projects/`. Read them each time. They may have changed since the last session, and your memory of them is not a source.

## Procedure

1. Read `$RUST_DEV_ENV/reference-projects/PRINCIPLES.md` and `COMMON_MISTAKES.md` completely.
2. For code, run the scanner. It reports likely NASA-rule problems with file and line:

```bash
python3 $RUST_AGENT_INFRA_DIR/harness/library/skills/principles-check/scripts/rust_rules_scan.py src/ [--max-fn-lines 60] [--strict]
```

3. For requirements and designs, apply the checklist in `references/rules.md` by reading.
4. Judge each hit. A scanner hit is a question. `unwrap()` on a value proven non-empty two lines above may be fine. Write why in the finding.
5. Report each real violation as `rule | location | why it matters | fix`. Mention which principles you checked and which you could not.

## Rules of thumb

- Report violations of the written principles, not personal style preferences.
- A deviation from a principle needs a written reason in the code or ADR. Accept it only when the reason is there.
- If PRINCIPLES.md and a requirement conflict, do not choose. Report it to the Coordinator.

## Steps (split points)

Use with `step-protocol`. 1. Read PRINCIPLES.md with `mem.py slice` (one part per step), `note` the rules that apply. 2. Scan one crate per step. 3. Judge hits, 10 per step. 4. Report.
