---
description: "[Mobile / Embedded] Shared Rust core with native UI shells"
agent: team-leader
---
Run `kctx run build-mobile-app $ARGUMENTS` in the shell and report only its short JSON result. Do not load other files.
Signature: /build-mobile-app <app> [--platform ios/android/both] [--core rust-uniffi/tauri-mobile]
Chain: @mobile-developer -> @ui-designer -> @ux-designer -> @software-quality-assurance-engineer
Output: Shared Rust core with native UI shells. Default gates: review, QA, security.
