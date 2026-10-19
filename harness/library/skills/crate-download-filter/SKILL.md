---
name: crate-download-filter
description: Enforce the rule that no Rust crate under 10000 all-time downloads is used. Use whenever a dependency is proposed, reviewed, or added.
---

# crate-download-filter

A low download count means little real-world testing and a higher risk of abandoned or unsafe code. The project rule is a hard threshold, so the check is a script and not a judgement call.

## Procedure

1. List the crate names (from the issue, a search result, or `Cargo.toml`).
2. Run:

```bash
python3 $RUST_AGENT_INFRA_DIR/harness/library/skills/crate-download-filter/scripts/check_crates.py serde tokio some-small-crate
```

Output: `PASS`, `FAIL`, or `NOTFOUND` per crate. Exit code 1 if any fail.
3. Omit every `FAIL` and `NOTFOUND` crate from your result. Do not argue for an exception. If a failed crate is the only option, say so in the comment and let the Coordinator ask the Human.
4. Transitive dependencies are out of scope unless the issue says otherwise. Direct dependencies are in scope.

## Notes

- "Downloads all time" is the `downloads` field on crates.io, not "recent downloads".
- Change the limit only for testing, with `--min-downloads` or `MIN_CRATE_DOWNLOADS`. The project value is 10000.
- If crates.io cannot be reached, report that. Do not guess the numbers.
