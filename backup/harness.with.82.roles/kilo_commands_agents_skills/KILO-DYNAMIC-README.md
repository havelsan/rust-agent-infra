# Dynamic context pack for small context windows

Built for a ~32K-token model. Almost everything lives in a cold **library** (about 44480 tokens in total, never loaded together). Kilo only discovers what is in the active folders, and `kctx` copies the few items a step needs into them and removes them afterwards.

## Memory levels
| Level | What | Where | In context |
|---|---|---|---|
| L0 core | rules, orchestrator agent, 2 universal skills, `/kctx` router | `.kilo/memory/L0-core.md`, pinned items | always (about 911 tokens) |
| L1 working set | one agent + up to 3 skills for the current step | `.kilo/agents|skills|commands` (copied from `.kilo/library`) | only during that step |
| L2 task memory | rolling epic summary (max 2400 bytes) + latest hand-off | `.kilo/memory/epics/<id>/` | every step of that epic |
| L3 project memory | decisions, conventions, epic digests | `.kilo/memory/project/` | only by `kctx recall`, max 2400 bytes |
| L4 org memory | cross-project lessons and conventions | `~/.kilo/memory/org/` | only by `kctx recall` |
| catalog | one line per agent/skill/command, plus the command-to-agent graph | `.kilo/catalog/` | only via `kctx catalog|search|plan` |

## How a workflow runs
`./kctx run port-module billing --from java:legacy/billing --to rust:crates/billing`
1. Validates the arguments and builds the plan: step order, agent per step, and the 1 to 3 most relevant skills per step.
2. Creates epic `E0001` (and a Gitea issue if `GITEA_URL`, `GITEA_TOKEN`, `GITEA_REPO` are set).
3. For every step: unload everything not pinned, load that step's agent and skills, build a prompt (L0 rules + L2 summary + recalled L3/L4 notes + step instructions), start a **fresh** session with `kilo run`, read the hand-off file the agent wrote, truncate it to 1200 bytes, update the rolling summary, unload.
4. Stops at blocked or needs-input hand-offs, at the human Product Owner gates (`kctx resume E0001 --approve` after the human decided), or when the chain is finished. Then `kctx close E0001` stores a short digest in L3.

Because each step is a new session, a skill loaded in step 3 is never in the context of step 4, and the Team Leader session only ever sees a short JSON result.

## Useful commands
```
kctx status                    budget table and what is loaded
kctx plan <command> [args]     show steps, skills and fixed-context cost (no changes)
kctx catalog --type skill      compact list;  kctx search "fuzz parser"
kctx load skill <name>         manual load (LRU eviction when over budget);  kctx unload --all
kctx pack list|load|unload     load a group of slash commands (for example java-rust)
kctx recall "<query>"          search L3/L4 (BM25, no extra services)
kctx remember 3 "<title>" --text "..."     save a note (max 1500 bytes)
kctx epics | resume <id> [--approve] | close <id>
```

## Topics every role must pay attention to before starting
Defined in `.kilo/memory/topics.json` (edit freely). They are written into the relevant agent files (section "Before you start") and injected into step prompts.

| # | Topic | Who | How it is enforced |
|---|---|---|---|
| 0 | Domain-driven design, clean code, test-driven development, always | code roles: developers (15-23, 71), reviewers (37, 32), architects (6, 7, 8), test roles (38, 39, 40) | Rules are inside those agent files. Reviewers reject violations. Skill `engineering-standards` with `standards_check.sh` checks the diff (tests added, IO-free domain code, no unwrap in domain code). Ponytail simplicity applies inside these rules, never against them. |
| 1 | Rust design patterns book | the Team Leader builds the summary, developers and reviewers obey it | `kctx preflight` (it also runs automatically at the start of `kctx run` when a developer or reviewer step is in the plan) reads `$RUST_DEV_ENV/books/rust_design_patterns.pdf`, summarizes it part by part in fresh Team Leader sessions, and writes `summaries/rust_design_patterns.pdf.md` with a quick reference on top, only if that file does not exist. Interrupted runs resume. The quick reference goes into developer and reviewer prompts, and the whole summary is searchable with `kctx recall`. |
| 2 | SDK common mistakes and principles | developers, reviewers | Digests of `$SDK_DEV_ENV/reference-projects/COMMON_MISTAKES.md` and `PRINCIPLES.md` (900 bytes each) go into their step prompts. Missing files are reported under "Open:" in the hand-off. |
| 3 | Karpathy guidelines | code roles | `.kilo/karpathy_skill.md` is the downloaded SKILL.md from the multica-ai/andrej-karpathy-skills repository, unchanged (its front matter says MIT license). A 1100-byte digest goes into prompts. |

Check status with `kctx topics` or `kctx doctor`. Summaries can also be made by hand: `kctx summarize <pdf>` or `/summarize-book`.
Assumptions to review: the role groups in `topics.json`; both SDK files live in `$SDK_DEV_ENV/reference-projects/`; the PDF has a text layer (scanned PDFs cannot be read); parts are about 12,000 bytes of text each (`topics.part_bytes` in `budget.json`), so a long book means many Team Leader sessions the first time.

## Token tools (rtk, caveman, graphify, ponytail)
Each tool attacks a different source of token waste, and each is wired in where it matters for a small window:

| Source of tokens | Tool | What this pack does |
|---|---|---|
| Shell command output | **rtk** | Step prompts tell agents to prefix commands with `rtk` (only when installed). The scripts wrap `cargo build/test/clippy/check`, `git status/diff/log`, `ls`, `find`, `grep` with rtk, but only after `kctx doctor` proved that rtk keeps exit codes (marker `.kilo/memory/rtk.ok`). `kctx status` shows `rtk gain`. |
| Agent replies and hand-offs (output) | **caveman** | The official skill adds about 1-1.5k input tokens every turn, which is too expensive here. Instead a 40-60 token style rule (`style.caveman` = lite/full/ultra/off in `budget.json`) goes into each step prompt. It covers replies and the hand-off only, never documents or code. `kctx compress <file>` (skill `memory-compression`) shrinks notes and docs, keeping code, paths and numbers exact, with an `.orig` backup. |
| Reading source files (input) | **graphify** | `kctx graph build` runs `graphify update .` (AST only, no API calls). Once `graphify-out/graph.json` exists, code-reading roles get the skill `codebase-graph-query`, a one-line hint, and an automatic `graphify query ... --budget` result inside their recall section (max 1200 bytes). Commands such as `assess-legacy` and `port-module` build the graph automatically when it is missing. |
| Writing code (output and later reading) | **ponytail** | Dev roles get the six-rung ladder (skip it, std, platform feature, existing dependency, one expression, minimum code) in their prompt (`style.ponytail`). Reviewers get the skill `ponytail-review` and the commands `/ponytail-review` and `/ponytail-audit`. Correctness and security are explicitly exempt. |

Install helper: `./kctx run setup-token-tools --yes`, or `bash .kilo/skills/scripts/tools_install.sh --yes`. Check everything with `kctx doctor`.

## Things to check
- **Budget.** `.kilo/memory/budget.json` assumes a 32,768-token window (1 token ~ 4 bytes). If you literally mean 32 KB (about 8,000 tokens), use the values in the `_notes` field.
- **Runner.** `run.cmd` defaults to `kilo run --agent {agent}` with the prompt as the last argument. I could not verify those flags for your Kilo version. Change `run.cmd` (or set `KILO_RUN_CMD`); if it contains `{prompt_file}`, the command is run through bash with the prompt file path substituted.
- **Directory names.** Same note as before: Kilo uses `.kilo/agent` and `.kilo/command` (singular); run `./link-canonical.sh` if the plural folders are not picked up. Skills use `.kilo/skills`.
- **Skills are chosen by keyword overlap** between the command and the skill descriptions, not by a model. Check `kctx plan` output; override a role choice with `--prefer N`.
- **Better recall.** Built-in recall is keyword search. To use your own vector or wiki service for L3/L4, set `KCTX_RECALL_CMD` to a command that takes `<query> <max_bytes>` and prints text.
- **rtk.** Documented to proxy common commands; I could not verify exit-code behavior for every subcommand, which is why scripts only use it after `kctx doctor` passes its failing-build probe. Verify `rtk cargo build|test|clippy` on your version.
- **graphify.** `graphify update .` is documented as the local AST refresh; I could not confirm it creates a graph from scratch on every version. If `kctx graph build` reports no graph file, run `/graphify .` once in an IDE session or set `GRAPHIFY_BUILD_CMD`. Docs and PDFs need an LLM backend (`graphify extract`).
- **caveman and ponytail.** Both are re-implemented as short built-in rules (my wording, not the projects' files), so nothing needs installing. The official versions target Claude Code style plugins; `--only caveman` in `tools_install.sh` installs the official caveman skill if you want it anyway.
- **Scripts.** 22 of 141 scripts are working; the rest are scaffolds that exit with code 3.
