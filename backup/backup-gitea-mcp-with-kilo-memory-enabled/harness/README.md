# agentic-team skills

Skills for the Human / Coordinator / Worker team that works through the Gitea issues and wiki of `project-01`.
Every skill is a folder with a `SKILL.md` (instructions) and, where useful, `scripts/` and `references/`.
Python scripts use only the standard library (Python 3.11+). Shell scripts use bash.

## Layout and install

| Folder | Installed to | Who gets it |
| --- | --- | --- |
| `base-skills/` | `$RUST_AGENT_INFRA_DIR/harness/base-skills/` | Coordinator and Worker (linked by `start_agents.sh`) |
| `coordinator-skills/` | `$RUST_AGENT_INFRA_DIR/harness/coordinator-skills/` | Coordinator |
| `worker-skills/` | `$RUST_AGENT_INFRA_DIR/harness/worker-skills/` | Worker |
| `library/skills/` | `$RUST_AGENT_INFRA_DIR/harness/library/skills/` | Worker, loaded per role |
| `library/roles/` | `$RUST_AGENT_INFRA_DIR/harness/library/roles/` | Worker, one file per role (`Analyzer.md` ...), read by `role-loader`. Existing files are kept unless `--force` |
| `agents-md/` | `$RUST_AGENT_INFRA_DIR/harness/agents-md/<role>/AGENTS.md` | Copied into each workspace root |

```bash
./install.sh "$RUST_AGENT_INFRA_DIR"          # copy (add --link to symlink, --force to overwrite)
python3 "$RUST_AGENT_INFRA_DIR/harness/base-skills/gitea-issues/scripts/gitea.py" ensure-labels
```

The existing `asd-ste100` skill is not part of this package. Keep it in `library/skills/`.

## Changes for start_agents.sh

Link the skills into each workspace (`.kilo/skills`) and set the environment of each agent process:

```bash
H="$RUST_AGENT_INFRA_DIR/harness"
link_skills() { # workspace, source dirs...
  local ws="$1"; shift; mkdir -p "$ws/.kilo/skills"
  for group in "$@"; do for s in "$group"/*/; do ln -sfn "${s%/}" "$ws/.kilo/skills/$(basename "$s")"; done; done
}
link_skills "$COORDINATOR_SPACE" "$H/base-skills" "$H/coordinator-skills"
link_skills "$WORKER_SPACE"      "$H/base-skills" "$H/worker-skills" "$H/library/skills"

# common
export GITEA_URL=... GITEA_OWNER=... GITEA_REPO=project-01 RUST_AGENT_INFRA_DIR
export MEM_DIR="$WORKSPACE/.mem" MEM_CONTEXT_TOKENS=32000   # per agent workspace
export HUMAN_USER=... COORDINATOR_USER=... WORKER_USER=...
# per agent: the scripts read GITEA_ACCESS_TOKEN
export GITEA_ACCESS_TOKEN="$COORDINATOR1_PERSONAL_ACCESS_TOKEN"   # in the coordinator process
export GITEA_ACCESS_TOKEN="$WORKER1_PERSONAL_ACCESS_TOKEN"        # in the worker process
```

Copy the agent instructions into the workspaces:

```bash
cp "$H/agents-md/coordinator/AGENTS.md" "$COORDINATOR_SPACE/AGENTS.md"
cp "$H/agents-md/worker/AGENTS.md"      "$WORKER_SPACE/AGENTS.md"
```

`clear_worker.sh` must not delete `.mem/` of an issue that is still in progress. If it does, `mem.py start` restores the state from the last checkpoint comment (L2).

Linking `library/skills` into the Worker workspace is optional. If you do not link it, the role files must point to the skill paths.

## Small-context design (32K tokens)

The agents are built for a model with a small window. Three rules keep every step inside it:

1. **Layered memory** (`agent-memory`, script `mem.py`). L0 context holds only the current step. L1 `.mem/<issue>/` holds plan, step results, and notes and survives `/reset`. L2 is a checkpoint comment on the Gitea issue, so a lost workspace or a different agent can resume. L3 is the wiki and the graphify graph. L4 is roles, skills, and principles, read in slices.
2. **Think, plan, execute small pieces** (`step-protocol`). At most 8 steps per plan, each about 4K tokens of work. A step that fails twice, touches more than 3 files, or prints more than 150 lines is split into 2 to 4 sub-steps. Missing information makes the issue `blocked`.
3. **Bounded output**. `get --brief`, wiki `get` in 6000-character parts, capped role files, capped scanner and report output, and `rt.sh` for shell commands.

Budget used in the `AGENTS.md` files: AGENTS and skill list 3K, role 2K, one active skill 1K, issue and recall 3K, each tool output 1.5K, the rest for thinking and writing. `AGENTS.md` is about 800 to 900 tokens. Each `SKILL.md` is 350 to 700 tokens. All skill descriptions together are about 1.5K tokens. If your window is really 32 KB (about 8K tokens), set `MEM_CONTEXT_TOKENS=8000` and link only the skills a role needs.

## Optional tools

All four are optional. Every script and skill works without them. Each tool is used in these places:

| Tool | What it does | Where it is used | Install |
| --- | --- | --- | --- |
| rtk (Rust Token Killer) | Compresses command output | `lean-shell/rt.sh`, and every cargo and git call in the gate scripts | `curl -fsSL https://raw.githubusercontent.com/rtk-ai/rtk/refs/heads/master/install.sh \| sh` or `cargo install --git https://github.com/rtk-ai/rtk`. Check with `rtk gain`. Do not use `cargo install rtk` |
| graphify | Knowledge graph of code and docs | `graph-memory/graph.sh`, used by Architect, Developer, Reviewer | `uv tool install graphifyy` or `pipx install graphifyy`. First build: `/graphify .` in the assistant, then `graph.sh build` |
| caveman | Short output style, memory file compression | `terse-mode`, short rules inline in both `AGENTS.md` | Copy `skills/caveman/SKILL.md` from github.com/JuliusBrussee/caveman to `.kilo/skills/caveman/` |
| ponytail | Stops over-building | `minimal-build`, short rule inline in both `AGENTS.md`, used by Developer and Reviewer | Copy the skills from github.com/DietrichGebert/ponytail to `.kilo/skills/` |

Run `base-skills/lean-shell/scripts/check_tools.sh` to see what is installed.

## Conventions used by all skills

- **Status** is a label: `status:todo`, `status:in-progress`, `status:blocked`, `status:done`.
- **Role** is the first line of the issue body: `Role: Developer`.
- **Comments** follow `issue-comment-protocol`.
- **Handoff**: Worker returns every issue to the Coordinator. Only the Coordinator assigns to the Human.
- The Worker does not close issues. The Coordinator closes them after checking.

## Skill index

### Base skills

| ID | Skill | Purpose |
| --- | --- | --- |
| B-01 | `gitea-issues` | Read, create, comment, assign, label, set status |
| B-02 | `gitea-wiki` | List, read, write wiki pages |
| B-03 | `issue-comment-protocol` | Standard comment format |
| B-04 | `gitea-assignment-handoff` | Who hands off to whom; comment + status + assign in one step |
| B-05 | `agent-memory` | Layered memory, plan and step tracker, checkpoint and restore (`mem.py`) |
| B-06 | `step-protocol` | Think, plan, execute small steps; when to split |
| B-07 | `lean-shell` | Small shell output with rtk (`rt.sh`) |
| B-08 | `graph-memory` | Query the graphify graph before reading files |
| B-09 | `terse-mode` | Caveman-style notes and comments; compress memory files |
| B-10 | `minimal-build` | Ponytail-style ladder and diff size limit per step |

### Coordinator skills

| ID | Skill | Purpose |
| --- | --- | --- |
| C-01 | `issue-triage` | Split a goal into Worker issues |
| C-02 | `role-selection` | Choose and write the role |
| C-03 | `human-escalation` | Ask the Human a decision question |
| C-04 | `progress-tracking` | Status report, stalled and blocked work |
| C-05 | `architecture-checkpoint` | Periodic Architect issue |

### Worker skills

| ID | Skill | Purpose |
| --- | --- | --- |
| W-01 | `issue-polling` | Pick the next assigned issue |
| W-02 | `role-loader` | Load the role named in the issue |
| W-03 | `issue-completion` | Comment, set status, hand back |
| W-04 | `worker-reset` | `clear_worker.sh`, then `/reset` and `/reload` |

### Role skills (library/skills)

| ID | Role | Skill |
| --- | --- | --- |
| R-01 | Analyzer | `asd-ste100` (existing, not included) |
| R-02 | Analyzer | `requirements-quality-check` |
| R-03 | Analyzer | `requirements-wiki-builder` |
| R-04 | Analyzer, Developer, Reviewer | `principles-check` |
| R-05 | Researcher | `crate-search` |
| R-06 | Researcher | `crate-download-filter` |
| R-07 | Architect | `architecture-assessment` |
| R-08 | Architect | `architecture-wiki` |
| R-09 | Architect | `ddd-clean-architecture` |
| R-10 | Developer | `rust-ddd-clean-arch-dev` |
| R-11 | Developer, Tester | `rust-tdd` |
| R-12 | Developer, Reviewer | `nasa-rules-solid` |
| R-13 | Designer | `ux-ui-design` |
| R-14 | Reviewer | `rust-code-review` |
| R-15 | Tester | `rust-test-writing` |
| R-16 | Qa | `release-checklist` |
| R-17 | Qa | `rpm-deb-packaging` |

## What was tested

The Gitea scripts and `mem.py` (including checkpoint and restore) were tested against a local mock of the Gitea API, not a real server.
rtk, graphify, caveman, and ponytail were not installed in the test environment, so only the fallback paths ran. The rtk and graphify command forms come from their documentation. Check them once against your Gitea version
(especially wiki calls and `assignees` handling). The crates.io scripts need network access to crates.io.
Cargo-based scripts (`tdd_cycle.sh`, `review_gate.sh`, `release_gate.sh`, `build_packages.sh`) need a Rust toolchain and were not run against a real project here.
