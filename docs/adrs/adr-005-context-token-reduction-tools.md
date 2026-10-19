# Architecture Decision Record: Selection of Codebase Context and Token Optimization Tools

## Status
Proposed

## Context
Developing and maintaining software with local, air-gapped, or terminal-native AI coding agents (such as Claude Code CLI, Open Code CLI, Aider, and custom harnesses) requires balancing two competing constraints:
1. **Context Richness:** Providing the LLM with sufficient structural awareness (dependency graphs, call hierarchies, architecture blueprints) so it writes correct code.
2. **Token Economy & Latency:** Minimizing raw token volume, eliminating conversational bloat, and preserving safe operating margins to prevent context overflow, thrashing, or high inference overhead.

To address these challenges, we evaluated six distinct utilities spanning code graph generation, prompt compression, token reduction, context budgeting, and session orchestration: **Codegraph**, **Graphify**, **Caveman**, **RTK**, **Headroom**, and **Ponytail**. 

---

## Evaluation of Alternatives

| Tool | Category | Primary Function | Strengths | Limitations |
| :--- | :--- | :--- | :--- | :--- |
| **Codegraph** | Code Intelligence | Builds static dependency graphs and AST relationship maps for source code repositories. | Pinpoints exact functional dependencies; excellent for multi-file refactoring and architectural navigation. Focuses strictly on code and symbol-level indexing as a lightweight, fully local runtime companion for your coding agent.| Static indexing overhead; does not optimize prompt text or token budgeting. |
| **Graphify** | Code Intelligence / Knowledge Graph | Indexes local repositories into lightweight knowledge graphs and relational maps for agent consumption. | Highly compatible with local vector/graph setups; reduces blind spot browsing by agents. Maps far beyond just code—it handles markdown, PDFs, spreadsheets, screenshots, audio/video transcriptions, and live PostgreSQL schemas into a unified knowledge graph. Code is parsed locally via Tree-sitter for zero tokens, while other media leverage model calls.| Requires initial indexing pass; overlaps functionally with Codegraph. |
| **Caveman** | Prompt & Output Shaping | Enforces ultra-concise, filler-free, raw code/diff outputs from LLMs. | Drastically reduces output token waste; eliminates conversational pleasantries and markdown fluff. | Strictly a behavioral/prompt modifier; does not manage underlying file context or system memory. |
| **RTK** | Token Reduction / Pre-processing | Strips comments, whitespace, boilerplate, and low-signal syntax before ingestion. | Maximizes raw token compaction across diverse file types; lightweight pre-processor. | Can strip helpful inline documentation if over-aggressive; requires careful parsing rules. |
| **Headroom** | Context Budgeting | Monitors active token consumption against hard context windows to maintain a safe working buffer. | Preventing silent context truncation and out-of-memory errors during long tool-use loops. | Passive monitoring tool rather than an active code-retrieval mechanism. |
| **Ponytail** | Session Orchestration | Manages prompt streams, tracks git diff states, and feeds targeted file slices to CLI loops. | Excellent glue for terminal-native agent workflows; bridges git state with active context. | Specialized utility; depends heavily on existing CLI harness configurations. |

---

## Decision
We will adopt a **layered composition strategy** rather than selecting a single monolithic tool, as these utilities serve complementary phases of the AI coding pipeline. Specifically:

1. **For Structural Context (Graph Layer):** Integrate **Graphify** as our primary static repository mapper. This will run during workspace initialization or pre-commit hooks to supply local agents with precise relational maps rather than dumping raw file trees.
2. **For Token Reduction & Output Purity (Efficiency Layer):** Deploy **RTK** for aggressive pre-processing and token minimization of ingested source files, paired with **Caveman** mode enforcement in agent system prompts to eliminate verbose conversational output and enforce raw patch delivery.
3. **For Operational Safeguards & Session Flow (Orchestration Layer): We will use **Ponytail** for managing git-aware file slicing during interactive CLI coding sessions.

---

## Consequences

### Positive
* **Maximized Context Efficiency:** Combining RTK's pre-processing with structural mapping ensures agents receive high-signal, low-noise context.
* **Deterministic Agent Behavior:** Caveman prompt enforcement prevents agents from generating conversational padding, saving output tokens and execution time.

### Negative
* **Toolchain Complexity:** Managing multiple distinct utilities requires robust initialization scripts and clear separation of concerns in development harnesses.
* **Maintenance Overhead:** Keeping indexers (Graphify/Codegraph) synchronized with rapidly evolving codebases demands automated background hooks.
