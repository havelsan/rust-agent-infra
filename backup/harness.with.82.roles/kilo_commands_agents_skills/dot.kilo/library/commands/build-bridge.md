---
description: "[Java→Rust] Temporary interop layer so Java and Rust coexist"
agent: team-leader
---
Run `kctx run build-bridge $ARGUMENTS` in the shell and report only its short JSON result. Do not load other files.
Signature: /build-bridge <module> [--kind http/grpc/jni-rs] [--direction java-to-rust/rust-to-java/both]
Chain: @software-development-engineer -> @backend-developer -> @platform-engineer
Output: Temporary interop layer so Java and Rust coexist. Default gates: review, QA, security.
