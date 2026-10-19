---
description: "[Physics] Crate layout, data layout, parallelism and GPU strategy"
agent: team-leader
---
Run `kctx run design-sim-architecture $ARGUMENTS` in the shell and report only its short JSON result. Do not load other files.
Signature: /design-sim-architecture <model> [--layout ecs/soa] [--parallel rayon/none] [--gpu wgpu/cuda/none]
Chain: @software-architect -> @system-architect -> @computer-hardware-engineer -> @performance-engineer
Output: Crate layout, data layout, parallelism and GPU strategy. Default gates: review, QA, security.
