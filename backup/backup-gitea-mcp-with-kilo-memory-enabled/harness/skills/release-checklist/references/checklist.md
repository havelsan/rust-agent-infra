# Release checklist (Qa)

## Automatic (release_gate.sh)
- Git tree clean, semantic version set.
- fmt, clippy (zero warnings), tests in release mode, release build.
- `cargo audit` if installed.
- No TODO, FIXME, or `todo!()` left in code.
- License, README, and CHANGELOG entry.

## By reading
- Every `accepted` requirement in the wiki `Requirements Index` is `implemented` or `verified`, with a test.
- No issue with `status:todo`, `status:in-progress`, or `status:blocked` that belongs to this release.
- The latest `Architecture Status` page has no open `high` finding.
- The Reviewer approved the last change set.
- Installation and removal were tried on a clean system (see `rpm-deb-packaging`).

## Decision
Release only when every item passes. A failed item goes back to the Coordinator with the evidence.
