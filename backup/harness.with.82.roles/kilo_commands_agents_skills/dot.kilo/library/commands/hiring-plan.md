---
description: "[Business] Role needs and interview kits"
agent: team-leader
---
Run `kctx run hiring-plan $ARGUMENTS` in the shell and report only its short JSON result. Do not load other files.
Signature: /hiring-plan <team> [--roles <list>] [--headcount N]
Chain: @hr-people-operations -> @recruiter-talent-acquisition -> @team-leader
Output: Role needs and interview kits. Default gates: review, QA, security.
