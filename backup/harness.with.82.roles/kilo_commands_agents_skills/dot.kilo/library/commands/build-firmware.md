---
description: "[Mobile / Embedded] no_std firmware with hardware-in-the-loop tests"
agent: team-leader
---
Run `kctx run build-firmware $ARGUMENTS` in the shell and report only its short JSON result. Do not load other files.
Signature: /build-firmware <device> [--mcu <name>] [--runtime embassy/rtic] [--hil-tests]
Chain: @embedded-systems-engineer -> @electronics-engineer -> @computer-hardware-engineer -> @software-test-development-engineer
Output: `no_std` firmware with hardware-in-the-loop tests. Default gates: review, QA, security.
