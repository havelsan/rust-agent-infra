---
name: engineering-standards
description: "Apply and check the house rules before and after coding: domain-driven design, clean code, test-driven development and the Karpathy guidelines; reviewers reject violations."
---
Script: `bash .kilo/skills/scripts/standards_check.sh` (run with --dry-run first). standards_check.sh inspects the diff against a base ref: source changes without new or changed tests, IO or framework imports inside domain code, and unwrap or expect in domain code
Do: read the issue and the hand-off, apply this skill, save results in the repo, report in the hand-off.
Rules: domain-driven design (ubiquitous language, bounded contexts as crates, entities/value objects/aggregates, repository traits at the domain edge, IO-free domain), clean code, test first. Run the script before hand-off; reviewers reject on its failures. Details: Before you start section of your agent file.
