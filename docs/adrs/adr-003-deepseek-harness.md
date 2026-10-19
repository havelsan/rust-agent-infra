# Architecture Decision Record (ADR): Integration of DeepSeek Harness alongside Kilo Code

## Status
Accepted / In Progress

## Context
Following our initial multi-surface gateway selection, engineering requirements demand specialized support for deep reasoning, cost-optimized batch processing, and offline testing workflows. While **Kilo Code** provides our primary multi-surface gateway and zero-markup routing layer, integrating a dedicated **DeepSeek Harness** establishes a specialized pipeline for native DeepSeek model interactions, advanced reasoning verification, and high-throughput local or API-driven execution.

---

## Evaluation Criteria

1. **Reasoning Specialization:** Native optimization for models featuring chain-of-thought architecture (e.g., DeepSeek-R1 series) and complex mathematical, algorithmic, or systems-level problem solving.
2. **Infrastructure Synergy:** Compatibility with existing local inference runtimes (vLLM, Ollama) and air-gapped development stacks without introducing redundant gateway layers.
3. **Execution Control:** Granular scriptability for automated evaluation loops, test generation, and multi-turn debugging cycles.

---

## Tool Synergy & Division of Responsibilities

| Dimension | Kilo Code | DeepSeek Harness |
| :--- | :--- | :--- |
| **Primary Role** | Universal multi-surface gateway, IDE integration, and cross-model API routing | Dedicated reasoning agent, batch execution harness, and DeepSeek-optimized pipeline |
| **Surface Coverage** | VS Code, JetBrains, CLI, Web, Slack | CLI, programmatic automation scripts, headless pipeline runners |
| **Cost & Token Model** | Zero-markup pass-through across 500+ models | Direct API/local model invocation optimized for high-token reasoning efficiency |
| **Primary Use Case** | Day-to-day multi-model coding, autocomplete, and contextual chat across IDEs | Deep algorithmic refactoring, architecture validation, and automated test harness execution |

---

## Decision

We formally adopt a **dual-tool strategy**, pairing Kilo Code as our universal multi-surface developer interface with a dedicated DeepSeek Harness for advanced reasoning and specialized code generation tasks.

* **Kilo Code Remains the Primary Gateway:** Retained for day-to-day IDE integration (VS Code, JetBrains), flexible model switching across 500+ endpoints, and standard cross-platform developer workflows.
* **DeepSeek Harness Added as a Specialized Execution Layer:** Deployed for complex algorithmic tasks, deep reasoning evaluations, and automated multi-file verification loops where native chain-of-thought handling is required.
* **Unified API Backend Integration:** Both systems will leverage shared local inference endpoints (such as vLLM or LiteLLM gateways) to maintain strict data privacy and avoid duplicate token overhead.

---

## Consequences

* **Positive:** Combines the universal multi-surface reach of Kilo Code with the high-performance reasoning capabilities of DeepSeek models; eliminates architectural blind spots in automated test and verification workflows.
* **Negative / Trade-offs:** Requires maintaining dual configuration files and managing distinct execution hooks between the IDE environment and terminal-based harnesses.
