# Architecture Decision Record (ADR): Native DeepSeek Harness Plugins vs. Model Context Protocol (MCP) Integration

## Status
Accepted

## Context
Operating the DeepSeek Harness alongside our primary multi-surface gateway (Kilo Code) requires establishing a standard for tool discovery, extension, and external resource connectivity. The DeepSeek Harness architecture natively supports an **"everything is a plugin"** philosophy powered by the Cordis runtime kernel, alongside standard bridging capabilities for the **Model Context Protocol (MCP)** via its built-in client (`@deepseek-ai/dsh-mcp-client`). 

We must define the structural boundaries for when to build or use native Cordis-based DeepSeek Harness plugins versus adopting external MCP servers.

---

## Evaluation Criteria

1. **Execution Lifecycle & Pipeline Control:** Native plugins can hook deeply into agent loops, event streams, validation passes, and pre-step modifications. MCP servers are strictly bounded to schema-defined tool execution and resource fetching over JSON-RPC transports.
2. **Portability & Ecosystem Reuse:** MCP offers a cross-assistant standard (reusable across Claude Code, Cursor, and Kilo Code), whereas native DeepSeek Harness plugins are bound to the Cordis runtime lifecycle.
3. **State Management & Sandboxing:** Native plugins share runtime context and memory hooks directly within the harness; MCP servers run as isolated subprocesses or remote HTTP streams, providing safer process boundaries at the cost of communication overhead.

---

## Technical Comparison

| Dimension | Native DeepSeek Harness Plugins (Cordis) | Model Context Protocol (MCP) |
| :--- | :--- | :--- |
| **Architectural Scope** | Can replace or modify models, UI components, session logs, agent loops, permissions, and tools. | Standardized protocol solely for exposing external tools, resources, and prompts. |
| **Lifecycle Hooks** | Deep interception: can rewrite model inputs, intercept tool execution, reject steps, or inject context. | Limited to request-response tool calls and resource reads initiated by the model/client. |
| **Portability** | Specific to the DeepSeek Harness ecosystem and Cordis-based runtimes. | Universal standard portable across multiple client runtimes (Claude, Cursor, Kilo Code, etc.). |
| **Isolation & Security** | Executes inside the harness process space or runtime profile context. | Runs in isolated processes or secure remote endpoints, limiting blast radius. |

---

## Decision

We establish a **hybrid extension model**, utilizing Model Context Protocol (MCP) servers for universal external integrations and data source connectors, while reserving native DeepSeek Harness plugins exclusively for core runtime, loop control, and pipeline governance.

* **Adopt MCP for External Tooling and Data Connectors:** All third-party integrations (such as GitHub, Jira, database access layers, and cloud services) will be integrated via standardized MCP servers mapped through the harness's MCP client configuration. This ensures that tool definitions remain portable across our broader developer toolchain (including Kilo Code).
* **Adopt Native Cordis Plugins for Harness-Specific Control:** Native DeepSeek Harness plugins will be restricted to internal runtime modifications—such as custom logging, security policy enforcement, specialized prompt transformers, and custom UI components (e.g., `dsh-better-sidebar`).
* **Strict Separation of Concerns:** Business logic and external API connections must never be tightly coupled to native harness extensions if an MCP-compliant architecture can achieve the same integration safely.

---

## Consequences

* **Positive:** Maximizes tool reusability across different AI agents in our stack via MCP; maintains granular event-loop and safety control inside the DeepSeek Harness via native Cordis plugins without locking core data sources into a single runtime.
* **Negative / Trade-offs:** Introduces operational complexity in managing dual configuration patterns (Cordis patch files for native components vs. MCP server transport configurations).
