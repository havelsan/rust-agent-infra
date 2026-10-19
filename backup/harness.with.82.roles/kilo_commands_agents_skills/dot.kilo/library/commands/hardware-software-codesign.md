---
description: "[Physics] Hardware/software partition and interface spec"
agent: team-leader
---
Run `kctx run hardware-software-codesign $ARGUMENTS` in the shell and report only its short JSON result. Do not load other files.
Signature: /hardware-software-codesign <device> [--mcu <name>] [--interfaces spi,i2c,can]
Chain: @electronics-engineer -> @computer-hardware-engineer -> @embedded-systems-engineer -> @software-development-engineer
Output: Hardware/software partition and interface spec. Default gates: review, QA, security.
