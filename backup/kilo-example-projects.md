# Two example projects for the Kilo dynamic pack

Together they run **every one of the 103 workflow commands**, put **every one of the 82 agents** to work, and pick **every one of the 140 skills**. Numbers below are computed from the pack's own catalog with the exact invocations listed in this file (every invocation was also parsed by the real `kctx` command line).

| | **PortPilot** (project A) | **RescueDrift** (project B) | **Together** |
|---|---|---|---|
| Workflow commands | 83 of 103 (81%) | 20 of 103, plus 8 shared lifecycle runs | **103 of 103** |
| Agents that run at least one step | 73 of 82 | 33 of 82 | **82 of 82** |
| Skills picked for a step (+2 always-on core) | 131 of 140 | 55 of 140 | **140 of 140** |
| Command runs in the plan | 88 | 23 (+8 shared) | 119 |

How to read this: an *agent* counts when it executes a step of a command in the plan; a *skill* counts when `kctx plan` auto-picks it for a step (the two core skills, `gitea-issue-management` and `role-handoff-protocol`, are loaded in every step by design). Commands whose chain offers alternative roles (`implement-task`, `build-ui`, `validate-physics`) are run several times with `--prefer`, which is why a few commands appear more than once.

**Why two projects.** PortPilot is a business-software program and reaches 80.6% of the commands. The remaining 20 commands need physics, hardware or life-science work that does not belong in a logistics system: the physics and simulation commands, firmware and embedded porting, and the biology and clinical reviews. RescueDrift supplies those.

Reachable only through RescueDrift:
- **Agents (9):** 21 Embedded Systems Engineer, 49 Mathematician, 50 Physicist, 51 Chemist, 52 Biologist, 53 Medical Doctor, 54 Mechanical Engineer, 55 Civil Engineer, 56 Electronics Engineer
- **Skills (9):** `chemistry-model-validation`, `circuit-and-signal-analysis`, `hardware-architecture-analysis`, `hardware-in-the-loop-testing`, `load-and-scalability-testing`, `mathematical-modeling-and-proofs`, `mechanical-and-structural-analysis`, `numerical-convergence-analysis`, `simulation-validation`

---

## Project A: PortPilot

**Modernize a legacy Java port-operations system into Rust, with a new UX, mobile app, ML and a full business around it**

**Scenario (fictional, to be adapted).** A harbor authority runs a 12-year-old Java 8 monolith with an Oracle database, a Swing desktop client and JSP pages for berth planning, cargo tracking, gate transactions and invoicing. The goal is to migrate it module by module to Rust (axum, sqlx, leptos, iced), redesign the dispatcher UX, add a pilot mobile app and an ETA-prediction model, and run the product like a real company: security, compliance, operations, customers, finance, hiring and IT. Assumptions: the legacy code and a copy of its database are available, and `$RUST_DEV_ENV` and `$SDK_DEV_ENV` point at your reference material.

### Requirements (59)

Save this list as `docs/requirements.md` and give it to `/intake-requirement`. The right column shows which commands realize or verify each requirement.

| ID | Requirement | Commands |
|---|---|---|
| A-001 | Repository, workspace layout, ADR folder and issue templates exist before any code is written. | `/init-project` |
| A-002 | Berth allocation assigns each vessel call a berth by size, draft, cargo type and time window and rejects conflicts. | `/intake-requirement`, `/design-feature`, `/implement-task`, `/review-pr` |
| A-003 | When an ETA changes by more than 30 minutes the system proposes a new berth plan within 10 seconds. | `/spike`, `/perf-regression` |
| A-004 | Cargo tracking follows each container from vessel to gate with status events and timestamps. | `/decompose-epic`, `/db-change` |
| A-005 | Gate transactions record plate, container and appointment ID; the EDI manifest parser never crashes on bad input. | `/fuzz-campaign` |
| A-006 | Invoices are produced per port call from tariffs with the legacy rounding and tax rules and exported as PDF. | `/port-module`, `/capture-behavior` |
| A-007 | Shipping agents use a customer portal to see calls, ETAs and invoices and to request services. | `/build-ui`, `/customer-demo` |
| A-008 | Pilots use a mobile app that works offline and confirms boarding with a location stamp. | `/build-mobile-app` |
| A-009 | Berth, ETA and status changes trigger e-mail, SMS or push notifications. | `/implement-task` |
| A-010 | Every change records who, when and what, and the audit trail is immutable for 7 years. | `/compliance-check`, `/db-change` |
| A-011 | Behavioral parity: on recorded production inputs the Rust system matches legacy results (zero tolerance for money, at most 1 minute for times). | `/capture-behavior`, `/parity-test`, `/port-module` |
| A-012 | Modules migrate one at a time behind feature flags, and each can be rolled back in under 15 minutes. | `/plan-migration`, `/cutover-module` |
| A-013 | Oracle data moves to PostgreSQL with dual-write and checksum reconciliation and no data loss. | `/migrate-data` |
| A-014 | The legacy service is retired after 30 stable days, with data and documents archived. | `/decommission-legacy`, `/train-and-document` |
| A-015 | Java and Rust coexist over gRPC during the migration; the legacy domain rules are recovered and documented first. | `/build-bridge`, `/assess-legacy`, `/recover-domain` |
| A-016 | The target architecture in Rust (async, API, database, UI) is decided and recorded as ADRs. | `/design-target` |
| A-017 | The dispatcher console is redesigned so that allocating a berth and handling a delay take at most 3 steps, with at least 90% task success in a usability test. | `/ux-audit-legacy`, `/redesign-ux`, `/build-ui` |
| A-018 | Terminal operators get an offline-tolerant desktop console. | `/build-ui`, `/implement-task` |
| A-019 | The UI is keyboard accessible and reviewed for cognitive load. | `/redesign-ux`, `/build-ui` |
| A-020 | An ETA prediction model reaches a mean absolute error of at most 20 minutes on a hold-out set and is retrained monthly. | `/build-ml-pipeline`, `/spike` |
| A-021 | A dispatcher assistant answers questions about the schedule, cites its data and leaks no personal data. | `/add-ai-feature` |
| A-022 | AI misuse and leakage risks are reviewed before release. | `/ai-safety-review` |
| A-023 | Berth utilization, turnaround time and waiting time are defined once in a metric layer. | `/define-metrics` |
| A-024 | The port director sees a dashboard refreshed daily. | `/build-dashboard` |
| A-025 | Scheduler v2 is compared with v1 on waiting time with a proper A/B analysis. | `/analyze-experiment` |
| A-026 | Domain crates have at least 80% line coverage and tests are written first. | `/coverage-gap`, `/test-cycle` |
| A-027 | All code follows domain-driven design, clean code and TDD, and the Rust design patterns summary. | `/standards-review`, `/review-pr`, `/refactor-debt` |
| A-028 | The allocation plan for 200 vessels completes in under 2 seconds at p95 and is not slower than the Java system. | `/perf-regression`, `/perf-compare` |
| A-029 | The scheduler is free of data races and deadlocks. | `/concurrency-review` |
| A-030 | No needless dependencies, abstractions or files are introduced. | `/ponytail-review`, `/ponytail-audit` |
| A-031 | Defects are reproduced, fixed with a regression test and verified. | `/bugfix` |
| A-032 | A STRIDE threat model exists for the payment gateway and the portal, with mitigations tracked. | `/threat-model` |
| A-033 | Dependencies and licenses pass audit; only allowed licenses are used. | `/dependency-audit`, `/license-review` |
| A-034 | Every use of unsafe is justified and audited. | `/unsafe-audit` |
| A-035 | An external penetration test of the customer portal ends with no open high finding at release. | `/pen-test` |
| A-036 | Authentication uses OIDC with role-based access, and hardening checks pass. | `/security-hardening`, `/design-feature` |
| A-037 | CI builds, tests, lints, audits and releases on Gitea Actions. | `/setup-ci` |
| A-038 | Services ship as small static container images. | `/containerize` |
| A-039 | Development, staging and production are defined as code. | `/provision-env` |
| A-040 | Deployments are canary with automatic rollback when an SLO is breached. | `/deploy`, `/release` |
| A-041 | Availability is 99.9% and p95 latency is 300 ms, tracked as SLOs. | `/define-slo` |
| A-042 | Incidents are classified by severity and followed by a post-mortem within 5 days; urgent fixes ship as hotfixes. | `/incident`, `/postmortem`, `/hotfix` |
| A-043 | A one-year capacity and cost plan exists. | `/capacity-plan` |
| A-044 | Configuration drift between environments is checked weekly. | `/env-drift-check` |
| A-045 | ISO 27001 control evidence is collected. | `/compliance-check` |
| A-046 | A launch plan and a proof-of-concept demo exist for the harbor authority. | `/launch-plan`, `/customer-demo` |
| A-047 | Terminal operators are onboarded with a checklist and configuration. | `/customer-onboarding` |
| A-048 | Support tickets escalate to engineering with reproduction steps and logs. | `/support-escalation` |
| A-049 | Customer feedback and usage data feed the roadmap every quarter. | `/feedback-loop`, `/plan-roadmap` |
| A-050 | An integration with the port community system is assessed technically and legally. | `/evaluate-partnership` |
| A-051 | Account health and renewals are reviewed for the harbor authority. | `/account-review` |
| A-052 | Quarterly budget review and cloud cost allocation at period close. | `/budget-review`, `/close-period` |
| A-053 | Three Rust engineers are hired with interview kits and policy-aligned performance reviews. | `/hiring-plan` |
| A-054 | A new developer gets a working environment in one day. | `/onboard-employee-env` |
| A-055 | IT access and asset policies are reviewed. | `/it-policy-review` |
| A-056 | The Product Owner gets a weekly status report; each milestone ends with a retrospective; blockers are escalated with options. | `/status-report`, `/retro`, `/escalate` |
| A-057 | Architecture disagreements are settled in an ADR. | `/arbitrate-design` |
| A-058 | The wiki and ADRs stay in sync with merged work, and agent output quality is audited each sprint. | `/knowledge-sync`, `/agent-audit` |
| A-059 | Context discipline: token tools set up, code graph built and queryable, memory compressed, design-patterns book summarized. | `/setup-token-tools`, `/graph-build`, `/graph-ask`, `/compress-memory`, `/summarize-book` |

### Workflow (copy and paste, in this order)

Run from the project root. `kctx plan <command> <args>` shows the steps, agents and context cost of any line first without running it.

**Phase 0 - Set up the workspace and the tools**
```
kctx run setup-token-tools
kctx run init-project portpilot --layout workspace --ci gitea-actions
kctx run setup-ci
kctx run summarize-book $RUST_DEV_ENV/books/rust_design_patterns.pdf
kctx run provision-env staging --cloud aws
kctx run onboard-employee-env new-rust-dev --toolchain rust,git
kctx run it-policy-review --areas access,assets
```

**Phase 1 - Discover the legacy system and the business**
```
kctx run intake-requirement berth-scheduling --source customer
kctx run plan-roadmap --horizon year --themes migration,mobile,ai
kctx run assess-legacy legacy/portcall-monolith --build maven --include-db --include-jni
kctx run graph-build
kctx run recover-domain all --from code
kctx run ux-audit-legacy dispatcher-console --personas
kctx run capture-behavior berth-allocation --method golden
kctx run spike eta-model-options --domain ml
kctx run evaluate-partnership port-community-system --integration-type api
kctx run compliance-check iso-27001
kctx run license-review
kctx run budget-review --period quarter --include cloud
```

**Phase 2 - Design**
```
kctx run redesign-ux dispatcher-console --design-system new --platform web --usability-test
kctx run design-target portpilot --async tokio --api axum --db sqlx --ui leptos
kctx run design-feature REQ-A-010 --ui yes --threat-model yes
kctx run plan-migration portpilot --strategy strangler
kctx run threat-model payment-gateway --method stride
kctx run arbitrate-design adr-12
kctx run decompose-epic epic-1 --granularity story
kctx run define-metrics berth-utilization --layer mart
```

**Phase 3 - Build and migrate**
```
kctx run build-bridge berth-allocation --kind grpc --direction both
kctx run port-module berth-allocation --from java:legacy/berth --to rust:crates/berth --strategy strangler
kctx run migrate-data --source oracle://legacy --dest postgres://new --mode dual-write --verify checksum
kctx run build-ui --design docs/ux/console.md --stack leptos --platform web
kctx run --prefer 18 build-ui --design docs/ux/console.md --stack leptos --platform web    # variant: another role from the chain
kctx run --prefer 20 build-ui --design docs/ux/ops.md --stack iced --platform desktop    # variant: another role from the chain
kctx run implement-task issue-12 --tests unit+integration async axum tokio service
kctx run --prefer 17 implement-task issue-12 --tests unit+integration async axum tokio service    # variant: another role from the chain
kctx run --prefer 16 implement-task issue-14 --tests unit    # variant: another role from the chain
kctx run --prefer 20 implement-task issue-15 --tests unit    # variant: another role from the chain
kctx run build-mobile-app pilot-app --platform both --core rust-uniffi
kctx run build-ml-pipeline eta-predictor --framework burn
kctx run add-ai-feature dispatcher-assistant --llm local
kctx run ai-safety-review dispatcher-assistant --risks leakage,misuse
kctx run db-change add-berth-index --type index
kctx run graph-ask who calls the berth allocator
```

**Phase 4 - Quality and security**
```
kctx run review-pr pr-31 --focus arch
kctx run standards-review
kctx run ponytail-review
kctx run ponytail-audit
kctx run refactor-debt crates/scheduler --goal modularity
kctx run test-cycle milestone-2 --types unit,integration,e2e
kctx run coverage-gap --min 80%
kctx run dependency-audit
kctx run unsafe-audit crates/berth
kctx run fuzz-campaign --target manifest_parser --duration 4h
kctx run concurrency-review crates/scheduler --tools loom
kctx run perf-regression crates/berth
kctx run parity-test berth-allocation --mode shadow-traffic
kctx run perf-compare --baseline java-1.0 --candidate rust-0.9 --metrics latency,memory
kctx run security-hardening berth-allocation --checks unsafe,authn
kctx run pen-test customer-portal --scope external
kctx run bugfix bug-77 --severity s2
```

**Phase 5 - Ship and operate**
```
kctx run containerize scheduler --base distroless
kctx run define-slo scheduler --slis latency,availability
kctx run capacity-plan scheduler --horizon 1y
kctx run env-drift-check --env staging
kctx run release --version 1.5.0 --channel stable
kctx run deploy scheduler --env staging --strategy canary
kctx run cutover-module berth-allocation --rollout canary:5%
kctx run hotfix inc-9 --version 1.4.1
kctx run incident alert-4412 --severity sev2
kctx run postmortem inc-9
kctx run decommission-legacy portcall-monolith --archive-db yes
```

**Phase 6 - Business, data and people**
```
kctx run launch-plan portpilot-2.0
kctx run customer-demo harbor-authority --poc yes
kctx run customer-onboarding terminal-operator-1
kctx run support-escalation ticket-5521
kctx run feedback-loop --sources tickets,usage
kctx run account-review harbor-authority --period quarter
kctx run analyze-experiment scheduler-v2-ab --method ab
kctx run build-dashboard port-director
kctx run hiring-plan platform-team --roles rust-engineers --headcount 3 policy performance review
kctx run close-period quarter --allocate cloud
kctx run train-and-document portpilot --audience ops
```

**Phase 7 - Governance and memory**
```
kctx run status-report --period sprint --audience po
kctx run retro milestone-2 policy performance
kctx run escalate issue-88
kctx run knowledge-sync --targets wiki,adr
kctx run agent-audit --period sprint
kctx run compress-memory .kilo/memory/project
```

---

## Project B: RescueDrift

**A man-overboard rescue buoy with a drift-prediction simulator, beacon firmware and medical safety review**

**Scenario (fictional, to be adapted).** A rescue buoy carries a beacon (GNSS, IMU, radio) and a ground station predicts where a person and the buoy will drift under wind, waves and current. The simulator is a large physics application in Rust; the beacon firmware is `no_std` Rust; the aluminium hull, the lithium battery, the cold-water survival model and the casualty alert thresholds each need a domain expert. This project exists to exercise the science, hardware and domain-expert agents and commands that PortPilot cannot. Assumptions: reference datasets (drifter tracks, hull load tests, bench data, survival data) are available under the names used in the commands.

### Requirements (24)

Save this list as `docs/requirements.md` and give it to `/intake-requirement`. The right column shows which commands realize or verify each requirement.

| ID | Requirement | Commands |
|---|---|---|
| B-001 | The system models the drift of a person in water and of the rescue buoy under wind, waves and current (leeway), in SI units with a documented validity range. | `/define-physics-model` |
| B-002 | Wave-driven (Stokes) drift is included up to sea state 5. | `/define-physics-model`, `/select-numerics` |
| B-003 | A thermal model gives body heat loss in cold water. | `/define-physics-model`, `/validate-bio-model` |
| B-004 | RK4 is the baseline integrator, with a symplectic option, and stability limits are documented. | `/select-numerics` |
| B-005 | Numerics are verified: convergence order 4 for RK4 on a manufactured solution, and conservation checks. | `/verify-numerics` |
| B-006 | Results are deterministic across thread counts and platforms. | `/ensure-determinism` |
| B-007 | An ensemble of 100,000 particles runs in under 60 seconds on 64 cores and scales to 1,000,000 in tests. | `/design-sim-architecture`, `/optimize-sim`, `/scale-test` |
| B-008 | Reference results are stored as regression baselines with a relative tolerance. | `/regression-baseline` |
| B-009 | Predicted drift tracks match NOAA drifter data within a normalized L2 error of 1e-3. | `/validate-physics` |
| B-010 | Hull and mooring loads are validated by mechanical and civil analysis. | `/verify-structural-model`, `/validate-physics` |
| B-011 | The beacon electronics (battery, radio, sensors) are validated by an electronics engineer. | `/validate-physics`, `/hardware-software-codesign` |
| B-012 | Battery behavior and corrosion of the aluminium hull in seawater are reviewed by a chemist. | `/validate-physics` |
| B-013 | The cold-water survival time model is validated against a dataset. | `/validate-bio-model` |
| B-014 | Casualty vital-sign alert thresholds follow a wilderness-medicine guideline and are reviewed by a doctor. | `/clinical-safety-review`, `/design-feature` |
| B-015 | The beacon firmware is no_std Rust (embassy) with hardware-in-the-loop tests. | `/build-firmware` |
| B-016 | The drift estimator runs on the beacon microcontroller within 64 KB of memory. | `/port-to-embedded` |
| B-017 | The hardware/software split and the SPI and I2C interfaces are specified. | `/hardware-software-codesign` |
| B-018 | The ground station shows a real-time map of the ensemble with an uncertainty cone. | `/build-viz` |
| B-019 | Scenarios are TOML files and results are Parquet and HDF5. | `/build-io-pipeline` |
| B-020 | The workspace has the crates core-math, physics, solver, io, viz and cli with typed SI units. | `/scaffold-workspace`, `/init-project` |
| B-021 | The solver is implemented and reviewed by a physicist and a mathematician for equation correctness. | `/implement-solver`, `/review-pr` |
| B-022 | A theory manual and a validation report are delivered. | `/document-model` |
| B-023 | Alternative integrators are evaluated before the choice is frozen. | `/spike` |
| B-024 | Requirements come from the Product Owner; the CLI is built, tested in cycles and released as 0.1.0. | `/intake-requirement`, `/implement-task`, `/test-cycle`, `/release` |

### Workflow (copy and paste, in this order)

Run from the project root. `kctx plan <command> <args>` shows the steps, agents and context cost of any line first without running it.

**Phase 0 - Reused lifecycle commands (also used by PortPilot)**
```
kctx run init-project rescuedrift --layout workspace
kctx run intake-requirement man-overboard-drift --source po
kctx run spike alternative-integrators --domain physics
```

**Phase 1 - Model the physics and the hardware**
```
kctx run define-physics-model man-overboard-drift --units si --validity-range
kctx run select-numerics drift-model --candidates rk4,symplectic --stability-analysis
kctx run verify-structural-model buoy-hull --loads dynamic
kctx run hardware-software-codesign beacon-board --mcu stm32 --interfaces spi,i2c
```

**Phase 2 - Build**
```
kctx run design-sim-architecture drift-model --layout soa --parallel rayon --gpu wgpu
kctx run scaffold-workspace rescuedrift --crates core-math,physics,solver,io,viz,cli --units uom
kctx run build-io-pipeline drift-model --formats parquet,hdf5 --scenario-config toml
kctx run implement-solver leeway --model docs/model/leeway.md --method rk4 --tolerance 1e-8 --backend rayon
kctx run build-firmware beacon --mcu stm32 --runtime embassy --hil-tests
kctx run port-to-embedded drift-estimator --target thumbv7em-none-eabihf --no-std --mem-budget 64k
kctx run build-viz drift-map --stack bevy --mode realtime
```

**Phase 3 - Verify and validate**
```
kctx run verify-numerics leeway --tests mms,convergence,conservation --order 4
kctx run ensure-determinism leeway --across threads,platforms
kctx run regression-baseline drift-model --tolerance-rule rel
kctx run validate-physics --against noaa-drifter-tracks --metric l2 --threshold 1e-3 --experts 51,54,55,56
kctx run --prefer 55 validate-physics --against hull-load-tests --metric linf --threshold 1e-2 --experts 55    # variant: another role from the chain
kctx run --prefer 56 validate-physics --against beacon-bench-data --metric l2 --threshold 1e-3 --experts 56    # variant: another role from the chain
kctx run --prefer 51 validate-physics --against seawater-corrosion-data --metric l2 --threshold 1e-2 --experts 51    # variant: another role from the chain
kctx run validate-bio-model cold-water-survival --against survival-dataset
kctx run clinical-safety-review casualty-vitals-alert --guideline wilderness-medicine
```

**Phase 4 - Optimize, scale, document**
```
kctx run optimize-sim ensemble --target simd
kctx run scale-test ensemble --cores 64 --size-range 1k-1M
kctx run document-model drift-model --parts theory,validation
```

**Phase 5 - Ship (reused lifecycle commands)**
```
kctx run design-feature REQ-B-014 --threat-model no
kctx run implement-task issue-3 --tests unit
kctx run review-pr pr-4 --focus arch
kctx run test-cycle milestone-1 --types unit,integration
kctx run release --version 0.1.0 --channel rc
```

---

## Practical notes

- **Do this once per workspace first:** `kctx doctor` (checks rtk, graphify, caveman, ponytail and the topic files), then `kctx preflight` (builds the design-patterns summary part by part). `summarize-book` in Phase 0 does the same by hand.
- **Commands that need things outside the sandbox:** `provision-env` and `deploy` need cloud credentials, `pen-test` needs written authorization, `migrate-data` needs both databases, `graph-build` needs graphify, `rtk` tools need rtk. Use `kctx plan` to inspect them and run them against a test setup.
- **Each `kctx run` step is a fresh session**, so a 100-command program is many small sessions, not one long one. Epics are numbered E0001...; use `kctx epics`, `kctx resume <id>` and `kctx close <id>` to manage them.
- **Human gates:** commands that end with Product Owner approval (for example `redesign-ux`, `design-target`, `intake-requirement`, `release`) stop and write a brief; continue with `kctx resume <id> --approve` after you decided.
- **If you want a single repository:** treat both projects as two epics of one program, for example *Maritime Safety Platform*, and run the same lines in one workspace.
