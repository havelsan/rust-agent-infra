---
description: "[Java→Rust] Benchmark comparison, Java versus Rust"
agent: team-leader
---
Run `kctx run perf-compare $ARGUMENTS` in the shell and report only its short JSON result. Do not load other files.
Signature: /perf-compare --baseline <ref> --candidate <ref> [--metrics latency,throughput,memory,startup] [--regress-limit 5%]
Chain: @performance-engineer -> @site-reliability-engineer
Output: Benchmark comparison, Java versus Rust. Default gates: review, QA, security.
