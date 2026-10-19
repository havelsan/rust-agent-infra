# Architecture Decision Record (ADR): Evaluation of Air-Gapped, Open-Source AI Coding Assistants

## Context and Problem Statement
Our engineering organization operates within a strict **air-gapped environment** with zero external network connectivity to public cloud APIs. We require an AI coding assistant and agentic workflow platform to accelerate development while meeting strict constraints:
1. **Air-Gapped Compatibility:** Must support local LLM backends (e.g., via vLLM, Ollama, or local model gateways) with no telemetry leaks or mandatory cloud dependencies.
2. **Open-Source Priority:** Source code must be available under permissive open-source licenses to allow local auditing, internal modifications, and self-hosting.
3. **Active Community & Maintenance:** Must feature a robust GitHub repository with active community adoption, regular releases, and broad ecosystem compatibility.

The candidates under evaluation are: **Kilo Code**, **Claude Code**, **Open Code**, **Aider**, **GitHub Copilot**, **OpenAI Codex**, **Replit Agent**, **Cursor**, and **Gemini CLI**.

---

## Decision Drivers & Evaluation Criteria
* **Air-Gapped & Local Model Support:** Can the tool route requests entirely to local inference endpoints (e.g., OpenAI-compatible local APIs)?
* **Open Source & Licensing:** Is the codebase open source (MIT, Apache 2.0, etc.) with a public GitHub repository?
* **Community & Ecosystem:** Star count, contribution frequency, and active user base on GitHub.
* **Agentic Capabilities:** Terminal control, multi-file editing, custom modes, and Model Context Protocol (MCP) support.

---

## Detailed Comparison of Options

| Tool | Open Source / License | Air-Gapped / Local Model Support | GitHub Community & Status | Primary Form Factor |
| :--- | :--- | :--- | :--- | :--- |
| **Kilo Code** | Yes (MIT) | **Native.** Fully supports custom model endpoints and local gateways (forked/expanded from OpenCode). | Very High (27k+ stars on GitHub) | VS Code, JetBrains, CLI, Cloud |
| **Open Code** | Yes (MIT / Apache) | **Native.** Designed for local and multi-provider routing via terminal interface. | High (Core foundation utilized by downstream agent tools) | Terminal TUI |
| **Aider** | Yes (Apache 2.0) | **Native.** Easily points to local endpoints via environment variables (`OPENAI_API_BASE`). | High (Very active Git-integrated assistant community) | CLI / Terminal |
| **Gemini CLI** | Yes (Apache 2.0) | **Partial.** Open source UI/CLI, but tightly coupled natively to Google Cloud / AI Studio endpoints (requires code modification/proxying for strict air-gapped local weights). | High (Backed by Google open-source initiatives) | Terminal TUI |
| **Claude Code** | Proprietary | **No.** Tied directly to Anthropic's cloud infrastructure and API. | Closed Source (Anthropic proprietary utility) | CLI |
| **GitHub Copilot** | Proprietary | **Limited.** Enterprise tiers offer some isolation, but core runtime demands GitHub cloud connections. | Proprietary Ecosystem | IDE Extensions |
| **OpenAI Codex** | Proprietary (Deprecated/Evolved) | **No.** Cloud-only API dependency. | Defunct / Superseded | API / Legacy Plugins |
| **Replit Agent** | Proprietary | **No.** SaaS cloud agent execution environment. | Proprietary Cloud Platform | Cloud Workspace |
| **Cursor** | Proprietary (Core IDE is fork of VS Code, backend services are closed) | **Partial.** Supports local model overrides, but telemetry and core features rely on cloud infrastructure. | Closed/Commercial Ecosystem | Standalone IDE |

---

## Evaluation of Defeated Options
* **Claude Code, GitHub Copilot, OpenAI Codex, Replit Agent, and Cursor** are rejected primarily due to being **proprietary**, closed-source, or tightly bound to external commercial clouds, violating core air-gap and open-source mandates.
* **Gemini CLI** is open-source (Apache 2.0) and feature-rich, but its architecture assumes integration with Google cloud backends (Gemini API / Vertex AI), making local air-gapped model rerouting secondary compared to native multi-model terminal tools.
* **Open Code** provides a robust terminal foundation, but has largely been superseded and absorbed upstream by its more feature-complete ecosystem evolution.

---

## Decision Outcome
**Selected Solutions:** **Kilo Code** (as the primary multi-interface agentic environment) and **Aider** (as the lightweight, git-centric terminal fallback).

### Justification:
1. **Strict Air-Gap & Local Model Compatibility:** Both Kilo Code and Aider natively support redirecting API base URLs to local inference engines (such as vLLM serving open-weight models like Llama-3 or Qwen inside the air-gapped datacenter) without forcing external telemetry.
2. **Open Source Alignment:** Both projects are fully open source under permissive licenses (MIT and Apache 2.0), enabling complete source code inspection and internal security vetting.
3. **Community Strength:** **Kilo Code** represents one of the fastest-growing open-source agent ecosystems on GitHub (over 27,000 stars), providing robust IDE extensions (VS Code, JetBrains) alongside its CLI. **Aider** offers battle-tested automated Git commit loops and multi-file editing optimized for local developer workflows.

### Implementation Architecture for Air-Gapped Environment:
* Deploy **vLLM** or **Ollama** on local GPU hardware (e.g., NVIDIA L40S / A40 nodes) to host open-weights foundational models.
* Configure **Kilo Code** or **Aider** environment variables locally to target the internal inference base URL (`http://localhost:8000/v1` or local gateway).
* Utilize Model Context Protocol (MCP) servers locally to give agents secure, read-only access to internal documentation stores without breaking the air-gap perimeter.
