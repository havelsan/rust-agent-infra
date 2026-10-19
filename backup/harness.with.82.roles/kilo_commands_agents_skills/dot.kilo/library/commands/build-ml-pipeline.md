---
description: "[AI / ML] Training, evaluation, and inference pipeline"
agent: team-leader
---
Run `kctx run build-ml-pipeline $ARGUMENTS` in the shell and report only its short JSON result. Do not load other files.
Signature: /build-ml-pipeline <model> [--framework burn/candle/onnx] [--stages train,eval,serve]
Chain: @machine-learning-engineer -> @data-engineer -> @data-scientist -> @performance-engineer
Output: Training, evaluation, and inference pipeline. Default gates: review, QA, security.
