---
name: interop-bridge-design
description: "Design and build temporary Java and Rust coexistence layers (HTTP, gRPC, JNI via `jni-rs`, or C ABI via `cbindgen`)."
---
Script: `bash .kilo/skills/scripts/ffi_check.sh` (run with --dry-run first). ffi_check.sh generates headers or bindings and checks ABI and signature drift between the two sides
Do: read the issue and the hand-off, apply this skill, save results in the repo, report in the hand-off.
