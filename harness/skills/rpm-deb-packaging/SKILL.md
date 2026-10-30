---
name: rpm-deb-packaging
description: Build and verify .rpm and .deb packages with cargo-deb and cargo-generate-rpm. Use for Qa packaging tasks after the release gate passes.
---

# rpm-deb-packaging

Users install packages, not source trees. A package with a wrong path or a missing file is a failed release even if all tests pass.

## Before you start

- `release-checklist` must have passed. Do not build packages from a failing tree.
- The binary crate needs package metadata. If it is missing, return the issue as `blocked` and ask for a Developer issue. Show the needed blocks from `references/cargo-metadata.md`. Qa does not edit source.

## Procedure

1. Check the tools: `cargo-deb` and `cargo-generate-rpm`. If they are missing, install them only if the issue allows it (`cargo install cargo-deb cargo-generate-rpm`). Otherwise report it.
2. Build:

```bash
$RUST_AGENT_INFRA_DIR/harness/library/skills/rpm-deb-packaging/scripts/build_packages.sh --crate-dir crates/interface --package myapp_interface --out dist
```

For a single-crate project, run it without options. The script makes the release build, the `.deb`, and the `.rpm` in `dist/`, and writes `SHA256SUMS`.
3. Verify the contents. The script prints package info. Also run `dpkg-deb --contents` and `rpm -qpl` and check: the binary path, the file modes, the license and README, and that no `target/` or test files are inside.
4. Test install and removal in a clean container or VM for each format. If you cannot, say so in the comment. Do not claim it works.
5. Comment on the issue (`issue-comment-protocol`): version, file names, sizes, checksums, and what you verified. Attach the files or give their path.

## Rules

- Package only the version that passed the gate. The version string in the file name must match `Cargo.toml`.
- Never sign or publish packages unless the issue says to.
- If the build fails, report the first error with the command and do not retry blindly.

## Steps (split points)

Use with `step-protocol`. Steps: check metadata, build, verify deb, verify rpm, install test, report.
