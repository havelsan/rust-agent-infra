---
description: "[Java→Rust] Inventory, dependency graph, debt, module classification (port/rewrite/retire)"
agent: team-leader
---
Run `kctx run assess-legacy $ARGUMENTS` in the shell and report only its short JSON result. Do not load other files.
Signature: /assess-legacy <java-repo> [--build maven/gradle] [--include-db] [--include-jni]
Chain: @software-architect -> @solutions-architect -> @software-review-engineer -> @database-administrator -> @application-security-engineer
Output: Inventory, dependency graph, debt, module classification (port/rewrite/retire). Default gates: review, QA, security.
