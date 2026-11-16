---
name: requirements-quality-check
description: Check requirements or an issue for consistency, ambiguity, contradiction, completeness, redundancy, validity, relevance, accuracy, clarity, correctness, entailment, satisfiability. Use for Analyzer review tasks.
---

# requirements-quality-check

Poor requirements cause the most expensive mistakes because everything else is built on them. The Analyzer finds problems while they are still cheap.

## Procedure

1. Read the Requirements wiki page of the gitea project, all comments, and the document it links. If the link cannot be opened, report that as the first finding and stop. Do not review from memory.
2. Run the lint script for a first pass on wording problems:

```bash
python3 .kilo/skills/requirements-quality-check/scripts/check_requirements.py requirements.md
```

It finds vague words, TBD markers, missing `shall`, long sentences, passive voice, duplicates, and possible contradictions. It cannot judge meaning.
3. Read each requirement against the twelve criteria in `references/criteria.md`. Spend most time on the ones a script cannot see: consistency across requirements, entailment, satisfiability, accuracy, correctness.
4. Run `asd-ste100` on the wording.
5. Write the findings to the wiki page `Requirements Review` (see `gitea-wiki`) using this table: `ID | criterion | severity | evidence | fix`.
6. Open a new gitea issue to the Coordinator for any `high` finding indicating to be forwarded to human.

## Judgement rules

- A finding needs evidence: a short quote and its location.
- Propose a concrete fix wording. Do not only say "unclear".
- Do not rewrite requirements yourself. Meaning belongs to the Human. Suggest and let the Coordinator escalate.
- Say what you could not check (for example, no access to a referenced standard).

## Steps (split points)

Use with `step-protocol`. 1. Read issue and last comments, `note` the document link. 2. Run the lint script. 3. Check 10 requirements per step against the criteria, `done` with the finding count. 4. One step for cross-checks (consistency, entailment, satisfiability) using your notes. 5. Write the wiki page. 6. Comment.
