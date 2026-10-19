---
name: legacy-java-analysis
description: "Inventory a Java code base: modules, dependencies, frameworks, JNI and native code, dead code, and hot spots."
---
Script: `python3 .kilo/skills/scripts/java_inventory.py` (run with --dry-run first). java_inventory.py parses Maven or Gradle files and the class graph and emits a JSON inventory with coupling metrics
Do: read the issue and the hand-off, apply this skill, save results in the repo, report in the hand-off.
