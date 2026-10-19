---
description: "[Java→Rust] Rust target architecture, crate boundaries, ADRs (PO approval)"
agent: team-leader
---
Run `kctx run design-target $ARGUMENTS` in the shell and report only its short JSON result. Do not load other files.
Signature: /design-target <system> [--async tokio/sync] [--api axum/tonic] [--db sqlx/diesel] [--ui leptos/egui/iced/tauri]
Chain: @system-architect -> @software-architect -> @solutions-architect -> @security-engineer -> @security-architect
Output: Rust target architecture, crate boundaries, ADRs (PO approval). Product Owner approval at the end.
