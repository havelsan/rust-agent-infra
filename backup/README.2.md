# agent-infra

Agent-infra repository contains scripts, descriptions and example use cases of a local/offline/air-gapped agentic development environment.

In this repository we describe: 
 
1. Architecture Design Records about tool/service choices among other alternatives.
2. How to trigger installation and services scripts.
3. Simple usage example of each tool/service individually.
4. Usage of these tools/services in a full cycle development scenario.


**CAUTION:**
1. "Kilo Code" wtiher CLI or VSCode extension, should be run in a non-privileged account of operating system. In ubuntu 24.04, perform the installations which are described below,  and start the services using an account with a SUDO privileged account. After starting the services
, you should switch to an account with no SUDO privilege while running "Kilo Code" executable or vs code extension.
 
2. If "Kilo Code" is using a system like issue tracker / DB / any type of server, the user account provided to "kilo code" agents should not have any admin privilege.

**ATTENTION:** 
1. After cloning this repository, source the release file found in the repository before running any script .
2. "Start scripts" in services directory only triggers the existing container if it exists. If you change anything in the script, you should remove the container. ( E.g :  sudo docker rm -f VLLM_0; cd services;./01.vllm.sh)


| Component | Type | Description |
| --------- | ---- | ----------- | 
| VLLM | SERVICE | LLM Inference Engine | 
| New API | SERVICE | LLM Proxy ( AI model gateway) | 
| Obsidian | TOOL | Obsidian is a popular note-taking and knowledge-management application that stores files as plain text Markdown documents on your local device| 
| Kilo-Code CLI | TOOL | An open source agentic command-line coding tool  | 
| Graphify | TOOL | an open-source tool and AI coding-assistant skill that turns a project's files—including code, documentation, PDFs, images, and videos—into a queryable knowledge graph | 
| Caveman | TOOL | Installed within Coding Agents. This tool reduces tokens before sanding to inference service |
| RTK | TOOL | Rust Token Killer is a command-line proxy sitting between your AI agent and the shell that intercepts verbose outputs (like git log) and returns clean, deduplicated, and condensed text |
| Ponytail | TOOL | It pushes the agent to reuse existing code, platform features, and dependencies before writing anything new. |



## Hardware and OS Requirements to Run This Environment:
	
1.  A computer with a NVIDIA GPU (with minimum 8GB RAM) that is supported by VLLM 

    For the list of GPUs supported by VLLM : https://docs.vllm.ai/en/stable/getting_started/installation/gpu/#requirements

    For the GPU size calculation : https://www.digitalocean.com/community/conceptual-articles/vllm-gpu-sizing-configuration-guide

2.  Ubuntu 24.04

3.  Sudo authorization in the operating system.

4.  100GB of disk space

##  Architecture Design Records

Architecture design records about :

1. Why we choose VLLM : [VLLM_ADR](docs/adrs/adr-001-ineference-engine-vllm.md)
2. Why we choose kilo-code among other coding assistants : [CODING_ASSISTANTS](docs/adrs/adr-002-ai-assistants.md)
3. How we use deep seek harness and kilo-code: [DEEP_SEEK_HARNESS_USAGE](docs/adrs/adr-003-deepseek-harness.md)
4. How we use Plugins/APIs and MCPs : [MCP_and_HARNESS](docs/adrs/aadr-004-mcp-vs-plugins.md)
5. How we do context token reduction :  [CONTEXT_TOKEN_REDUCTION](docs/adrs/adr-005-context-token-reduction-tools.md)


##  Installation of Services and Tools 

Clone this repository into your wworkspace directory, source the release file and run the ~/workspace/agent-infra/install/00.main.sh  script.
    
##  Starting Services

After installing services and tools, source the ~/workspace/agent-infra/release file then start services by running the ~/workspace/agent-infra/services/00.main.sh script.


## Simple Usage Example 

After starting the services, we are ready to use kilo agentic coding tool. 

#### Prepare Work Directory

	mkdir -p ~/agentspace/agent-managed-rust-project
	cd ~/agentspace/agent-managed-rust-project


	
#### Code Generation
We prepared rust development environment using https://github.com/havelsan/rust-dev-env in directory ~/sdk/rust-dev-env and we will use the compiler and cargo from that directory.

	source ~/sdk/rust-dev-env/release
	source ~/workspace/agent-infra/release
	cd ~/agentspace/agent-managed-rust-project
	## NOTE: WE USE CTRL-INSERT TO PASTE TEXT.
	kilo
		> 1. create a directory with name simple_calculator
		> 2. create a rust project with the same name in simple_calculator
		> 3. implement a simple calculator in main.rs with the following detail :
		  3.1. main.rs reads first value, math operator, second value as float value from terminal
		  3.2. main.rs performs the operation 
		  3.3. main.rs prints the result
		> 4. run the main and feed the values 5 + 2 if interactive.
		> 5. commit all source codes in simple_calculator to the git with a meaningful comment :)
			> The LLM Says : Done. Source code committed to git with meaningful commit message.
		> exit
		
	
#### Code Review

	source ~sdk/rust-dev-env/release
	source ~/workspace/agent-infra/release
	cd ~/agentspace/agent-managed-rust-project
	kilo
		> your role is "code reviewer". review the code in the simple_calculator directory and evaluate the codes by using the coding principles in ~/sdk/rust-dev-env/reference-projects/PRINCIPLES.md and ~/sdk/rust-dev-env/reference-projects/COMMON_MISTAKES.md. Run cargo clippy --all-targets --all-features to verify warnings. Note the issues into the ~/agentspace/agent-managed-rust-project/simple_calculator/issues/REVIEW-001.md  file.
			> The LLM generates comments in ~/agentspace/agent-managed-rust-project/simple_calculator/issues/REVIEW-001.md (262 lines)


#### Code Improvement

	source ~sdk/rust-dev-env/release
	source ~/workspace/agent-infra/release
	cd ~/agentspace/agent-managed-rust-project
	kilo
		> Make a step by step plan for to improve the code in simple_calculator project using the code review notes in ~/agentspace/agent-managed-rust-project/simple_calculator/issues/REVIEW-001.md and write the into ~/agentspace/agent-managed-rust-project/simple_calculator/plans/PLAN-01.md.  Steps of the plan should be as small as possible so that we can fit into 32k context :) 
			> The LLM Says : Plan generated.
		> Execute each step one by one. Write the executed steps of the plan into ~/agentspace/agent-managed-rust-project/simple_calculator/plans/PLAN-REPORT-01.md
			> The LLM Says : Compaction exhausted: context still exceeds model limits after 3 attempts


As you see from the LLM response, LLM could not make the improvement, so we tried to reduce the number of tokens, wihch is shown in next section.

#### Code Improvement Using Token Reduction Tools

Now we configure token reduction tools, you may check the descriptions of each tool that is used below from the [ Token Reduction ADR ](docs/ards/adr-005-context-token-reduction-tools.md)


	source ~sdk/rust-dev-env/release
	source ~/workspace/agent-infra/release
	cd ~/agentspace/agent-managed-rust-project
	rtk init --agent kilocode
	graphify kilo install
	graphify .
	graphify cluster-only .
	echo "## Context Navigation (Graphify Memory)
             - Always check 'graphify-out/' or 'graphify-out/obsidian/' to understand the codebase structure and module relationships before exploring raw source files.
             " > ~/agentspace/agent-managed-rust-project/AGENTS.md 
	caveman run -- kilo
		> Execute each step one by one. Write the executed steps of the plan into ~/agentspace/agent-managed-rust-project/simple_calculator/plans/PLAN-REPORT-01.md . run the tests one last time before returning me.
			> The LM Syas : All 8 tests passed successfully. The tests cover:
					- Arithmetic operations: addition, subtraction, multiplication, division
					- Error cases: invalid first value, invalid second value, invalid operator, division by zero

Use "rtk gain" to see how much you saved by using rtk.

Use "caveman stats" to see how much you saved by using caveman. 
        
To be sure about graphify output is used by kilo code , we ask to kilo code : "What are the primary God nodes and cross-module connections in this codebase based on the graphify report"
        
        

##  Installing the Agent-Infra's Code Development Harness in your project

0. Switch to a user that can NOT execute sudo commands, and also that does NOT have git master/tag privileges.
1. Clone a copy of your project into a directory.
2. Checkout a branch that "kilo code agent" can commit. (or even push)
3. Source the release file : ~workspace/agent-infra/release 
4. Run the harness installation script : ( ~workspace/agent-infra/harness/install_kilo_harness.sh)  

This command create .kilo directory if it does not exists , and creates links (if not exists) to the skill/mode/workflow files found in the ~/workspace/agent-infra/harness directory.

NOTE: we could also install in ~/.config/kilo/ directory. But we don't prefer to make a global installation, we install to only in-repository <project_dir>/.kilo directory.

##  How to Write Prompt

1. Don’t spam prompts to fix errors (Prompt Trashing).
2. Don’t assume model is understanding (Write Clear Prompts)
3. Don’t use too many MCP Servers / Skills / Modes / APIs ... (Risk of selecting wrong service/api would increase)
4. Regularly reevaluate (possibly outdated) assumptions about the "best" tools, skills, modes, mcps, apis ...
5. Don’t persist with dead-end conversations
5. Chain of Tought (COT) : Explain step by step what to do.
6. Input Data (previous mails, examples) should be given in paranthesis.
7. Output Data format should be explicitly specified ( list, table, json format, code, ...) 
8. If you want to emphasize something not to do, especially explain it so.
9. Specify who the output is intended for (e.g., beginner, researcher, executive, child).
10. Give explicit constraints: State requirements such as length, language, format, scope, exclusions, or deadlines.
11. Define what “success” means: Give measurable or observable criteria for a satisfactory answer. 
12. Ask for grounded reasoning: For factual or analytical tasks, request that conclusions be supported by the provided evidence or reliable sources.
13. Handle ambiguity explicitly: Tell the model whether it should ask questions, make reasonable assumptions, or provide alternatives when information is missing.
14. Decompose complex tasks: Break large objectives into sequential subtasks rather than asking for everything simultaneously.
15. Specify uncertainty behavior: Tell the model what to do when it does not know something: flag uncertainty, ask for clarification, or refrain from guessing.
16. Minimize hidden assumptions: If something matters to the result, put it explicitly in the prompt rather than assuming the model will infer it.
17. Treat the prompt as a specification: he strongest prompts resemble a good technical specification: objective + context + inputs + constraints + procedure/criteria + output format + quality requirements.
18. Venn Diagram of what is possible : Define information sets. Use intersection, union and exclusion while defining new rules.

## How to Write Skill


Skills are called automatically by kilo code agent. 

The directory structure is :

	.kilo/skills/your-skill-name/
	├── SKILL.md # Required - main skill file
	├── scripts/ # Optional - executable code
	│   ├── process_data.py # Example
	│   └── validate.sh # Example
	├── references/ # Optional - documentation
	│   ├── api-guide.md # Example
	│   └── examples/ # Example
	└── assets/ # Optional - templates, etc.
	    └── report-template.md # Example

.kilo directory (which also contains agents/modes and workflows/commands) is found in the main project directory (for example in the root directory of the project's git repository ( you can also use .agents instead of .kilo directory name and commit to git repo, .kilo name is ignored by default ).

1. Kilo Session starts ( you issue the command "kilo" )
   --> Kilo Code Agent loads: name + description from every skill (~100 tokens each)
2. User asks: "Can you write a README for this project?"
   --> Agent reads: readme-writer/SKILL.md full body (Level 2)
3. SKILL.md references a style guide file
   --> Agent reads: readme-writer/references/style.md (Level 3)
4. SKILL.md includes a validation script
   --> Agent executes: scripts/validate.sh 
   (runs without being read into context)


The description field in your YAML frontmatter is not for humans. It is the trigger condition the agent uses when deciding whether to activate your skill. 
	description: [What the skill does] + [When to use it, with specific trigger phrases] + [Key capabilities]
Bad Example: 
	description: Creates sophisticated multi-page documentation with advanced formatting.
Good Example: 
	description: Creates and writes professional README.md files for software projects. Use when user asks to "write a README", "create a readme", "document this project", "generate project documentation", or "help me write a README.md".

The agentskills.io spec defines the skill constraints:
1. name: lowercase letters, numbers, and hyphens only, max 64 characters, must not start or end with a hyphen, no consecutive hyphens
2. description: max 1024 characters, must describe both what the skill does and when to use it
3. The file must be named exactly SKILL.md, case-sensitive
4. Avoid XML angle brackets (< or >) in frontmatter as they can inject unintended instructions into the system prompt


Tests :

1. Triggering tests
   Goal: Ensure your skill loads at the right times.
   Test cases:
     - Triggers on obvious tasks
     - Triggers on paraphrased requests
     - Doesn't trigger on unrelated topics
2. Functional tests
   Goal: Verify the skill produces correct outputs.
   Test cases:
     - Valid outputs generated
     - API calls succeed
     - Error handling works
     - Edge cases covered
3. Performance comparison
   Goal: Prove the skill improves results vs. baseline.
   How will you know your skill is working :
      - Skill triggers on 90% of relevant queries
        – How to measure: Run 10-20 test queries that should trigger your skill. Track
          how many times it loads automatically vs. requires explicit invocation
      - Completes workflow in X tool calls
        – How to measure: Compare the same task with and without the skill enabled.
          Count tool calls and total tokens consumed.

Always write in third person. The description is injected into the system prompt, and inconsistent point-of-view can cause discovery problems.

    Good: "Processes Excel files and generates reports"
    Avoid: "I can help you process Excel files"
    Avoid: "You can use this to process Excel files"


ATTENTION : You have to write descriptions as clear as possible and non-ambiguous, beacuse Your Skill shares the context window with :

    The system prompt
    Conversation history
    Other Skills' metadata
    Your actual request


Define clear boundaries:

	Start with a short section that explains when this skill should be used. Is it intended for API usage? CLI workflows? 
	Git repositories? Specific permission levels? Being explicit about scope prevents agents from applying the wrong logic
	in the wrong context, and setting clear boundaries dramatically reduces misuse.

Provide a structural overview:

	Before describing workflows, orient the model. Identify the core objects in your product, key configuration files, or 
	primary entry points. This gives the agent a mental map of your system before it begins acting. LLMs perform better when they
	understand structure first, then action.

Document workflows — not features:

	Avoid abstract feature descriptions. Instead, describe how to complete real tasks step by step. If a workflow requires a specific
	sequence, state the order directly. If permissions, prerequisites, or environment setup are required, list them clearly. Precision
	reduces ambiguity — and less ambiguity makes AI behavior more reliable.

Include simple “if/then” decision rules:

	If there are multiple ways to accomplish something, clarify when to choose one over another. Short “if/then” guidance in plain
	language can significantly improve consistency. For example: if the task requires sequential steps, follow the ordered process;
	if it presents alternatives, surface options clearly. These lightweight rules help LLMs choose correctly instead of guessing.

Add guardrails and common pitfalls:

	Your skill file shouldn’t just describe what can be done — it should also define limits. Include a short section that outlines
	unsupported actions, configuration conflicts, environment constraints, or known failure modes. Negative constraints are powerful 
	for LLMs. They reduce subtle mistakes that would otherwise require human review. Finally, ensure your skill.md stays aligned with 
	your broader product documentation. It isn’t a replacement for full technical documentation — it’s a focused layer that helps AI
	agents use it correctly. If you already have product docs, this skill generator can help you build a skill.md draft from your 
	existing documentation, giving you a head-start in building skills for your product. It will still need reviewing and improving
	manually, but it may kickstart this process for you.


References :

	https://www.gitbook.com/blog/skill-md
	https://resources.anthropic.com/hubfs/The-Complete-Guide-to-Building-Skill-for-Claude.pdf
	https://bibek-poudel.medium.com/the-skill-md-pattern-how-to-write-ai-agent-skills-that-actually-work-72a3169dd7ee
	https://levelup.gitconnected.com/the-simple-guide-to-agent-skills-3d510521f11a
	https://www.skillsdirectory.com/docs/skill-file-structure
	https://ai.sulat.com/writing-opencode-agent-skills-a-practical-guide-with-examples-870ff24eec66
	https://github.com/mgechev/skills-best-practices
	https://platform.claude.com/docs/en/agents-and-tools/agent-skills/best-practices
	https://github.com/VoltAgent/awesome-agent-skills
	https://github.com/sickn33/agentic-awesome-skills


### Why does it matter?

Where it actually helps:

- Consistency over time/across sessions. Without a SKILL.md, Kilo might reach for a different error-handling style, crate, or pattern each session (e.g. anyhow vs thiserror, Arc<Mutex<>> vs message-passing). A SKILL.md locks in one approach, so the codebase doesn't accumulate stylistic drift — which is a real, measurable quality factor (readability, maintainability).
- Avoiding repeated known mistakes. If your project has caught Kilo (or anyone) making a specific class of error before — e.g., a lifetime-related footgun, wrong async runtime assumption, a bad pattern for FFI/unsafe blocks — writing that down means it isn't repeated. This is a real quality lift because it encodes negative feedback that pure code-reading can't surface.
- Correct project-specific context. Things like "this compiles with no_std," "we target this MCU/toolchain version," "this crate is banned for licensing reasons" — get these wrong and code technically compiles but is wrong for your constraints. A SKILL.md prevents that class of error entirely.
- Enforcing verification steps. If the SKILL.md says "always run cargo clippy --all-targets -- -D warnings and cargo test before considering a task done," that's a real quality gate that wouldn't otherwise happen automatically.

Where it doesn't help:

- It won't make Kilo better at algorithm design, borrow-checker reasoning, or catching subtle logic bugs — that's a function of the model's underlying capability, not the presence of a document.
- A vague or generic SKILL.md ("write clean code," "follow best practices") adds essentially nothing — the value is proportional to how specific and enforceable the instructions are.

So: think of it less as "smarter Rust" and more as "fewer preventable mistakes and less inconsistency" — which is a genuine quality improvement, but a different kind than raw coding skill.

### Example Skill

Directory Structure :

	.kilo/
	└── skills/
	    └── summarizer-skill/
	        │
		├── SKILL.md              # Main entry point and instructions for the agent
		├── scripts/              # Executable code or helper scripts used by the agent
		│   └── process_text.py   # Python utility to perform the core task
		├── references/           # Documentation, guidelines, or source materials
		│   └── formatting_rules.md # Style guide or schema the agent must follow
		└── assets/               # Static files, templates, or binary resources
		    └── template.md       # Output markdown template

When the agent is invoked with this skill, it inspects SKILL.md, runs the code inside scripts/ to handle heavy lifting, references the guidelines in references/ for formatting checks, and populates the template found in assets/ to produce the final result.


SKILL.md :

	
	---
	name: text-summarizer
	description: Guides stable API and interface design. Use when designing APIs, module boundaries, or any public interface. Use when creating REST or GraphQL endpoints, defining type contracts between modules, or establishing boundaries between frontend and backend.

	---


	# Text Summarizer Skill

	## Overview
	This skill processes raw text inputs, applies structural formatting rules, and generates a clean, standardized report.

	## Directory Layout
	* `scripts/`: Contains the execution logic (`process_text.py`).
	* `references/`: Contains compliance and formatting guidelines (`formatting_rules.md`).
	* `assets/`: Contains output templates (`template.md`).

	## Execution Steps
	1. Read the input text provided by the user.
	2. Execute the processing script to extract key metrics and summaries:
 	  ```bash
	   python scripts/process_text.py --input "path/to/input.txt"
	   ```
	3. Consult references/formatting_rules.md to ensure compliance with output standards.
	4. Render the final output using the structure defined in assets/template.md.

scripts/process_text.py: 

	#!/usr/bin/env python3
	import argparse
	import sys

	def summarize_text(text: str) -> dict:
	    words = text.split()
	    return {
	        "word_count": len(words),
 	       "preview": " ".join(words[:10]) + ("..." if len(words) > 10 else "")
  	  }

	if __name__ == "__main__":
 	   parser = argparse.ArgumentParser(description="Process and summarize input text.")
  	  parser.add_argument("--input", type=str, required=True, help="Text to process")
 	   args = parser.parse_args()
    
 	   result = summarize_text(args.input)
	   print(f"Word Count: {result['word_count']}")
 	   print(f"Preview: {result['preview']}")

references/formatting_rules.md:

	# Formatting Compliance Rules
	1. **Tone:** Keep all generated summaries objective and concise.
	2. **Structure:** Every report must begin with metadata (Word Count, Timestamp).
	3. **Language:** Avoid colloquialisms and filler words.

assets/template.md:

	# Execution Report

	**Status:** SUCCESS  
	**Word Count:** {{word_count}}  

	## Executive Summary
	{{preview}}
	

## How to Write Modes (Agents/SubAgents)

Directory Structure :

	.kilo/
	└── agents/
	    └── *.md


1. Structure of an Mode (Agent) .md File
   An agent file consists of two primary sections: 
   - YAML Frontmatter (Header between --- blocks) : Defines metadata, UI appearance, and tool/file permissions.
   - Markdown Body: Acts as the system prompt or role definition that shapes the agent's behavior, tone, and methodology.
    
2. Best Practices for Frontmatter (Header between --- blocks) Configuration
   The frontmatter dictates what the agent can and cannot do. Leverage granular permissions to optimize safety and focus:
   - Restrict Tool Access: Limit high-risk capabilities like shell commands (bash) or unrestricted file editing for read-only or specialized review agents.
   - Use Precise File Globbing: Restrict the edit permission to specific file extensions to prevent accidental modifications to core source code.
   - Set Clear Descriptions: Write concise summaries in the description field so users understand the agent's exact use case in the agent picker.

3. Best Practices for Writing Agent Instructions (Body)
   Define a Strong Persona Immediately: Start the markdown body with a direct statement defining the agent's role (e.g., "You are a technical writing expert specializing in clear documentation...").

   - Keep Instructions Focused: Unlike project-wide AGENTS.md files (which handle global codebase rules), individual agent files should focus purely on how that specific agent executes its specialized task.
   - Specify Behavioral Constraints: Explicitly state what the agent should avoid doing (e.g., "Do not modify implementation source code" or "Always ask before executing destructive shell commands").
   - Use Clean Markdown Formatting: Organize guidelines using headers, bullet points, and bold text so the LLM parses the hierarchical instructions accurately.


Frontmatter Fields :
- description : String : A short summary displayed in the agent picker and used by the orchestrator for task delegation.
- mode : String : Role classification:• primary (user-selectable in the UI)• subagent (only invoked by other agents)• all (both) 
- model :  String : Pins a specific model using provider/model format (e.g., anthropic/claude-sonnet-4-20250514). 
- permission :  Object : Per-agent permission overrides controlling tool access (e.g., allowing or denying edit, bash).
- color : String : UI identifier color for the agent picker, specified as a hex code (#10B981) or theme keyword (primary, accent, warning). 
- steps : Integer : Maximum agentic iterations allowed before forcing a text-only response. 
- temperature / top_p : Number : Sampling parameters for the agent's underlying model. 
- variant : String : Default model variant. 
- hidden : Boolean : If true, hides the agent from the UI (typically used for background subagents). 
- disable : Boolean : If true, completely disables and removes the agent. 

Note: The agent's identifier (name) is automatically derived from its filename (minus the .md extension). Nested subdirectories create namespaced names, such as agents/backend/sql.md resulting in backend/sql.


Core Guidelines

- Clarity First: Explain complex technical concepts simply, targeting both beginner and advanced developers.
- Strict Scope: You are only permitted to edit Markdown (.md or .mdx) files. Do not attempt to modify source code files.
- Structure: Always organize documentation with logical headings, tables where appropriate, and actionable code examples.
- Tone: Professional, objective, and instructional.

References :

	https://github.com/jtgsystems/Custom-Modes-Roo-Code/
	https://github.com/rahulvrane/awesome-claude-agents
	https://github.com/anderfredx/awesome-claude-code
	https://github.com/asgeirtj/system_prompts_leaks
	https://github.com/0xfurai/claude-code-subagents
	https://github.com/wshobson/agents
	https://github.com/VoltAgent/awesome-claude-code-subagents

### Why does it matter?
Net effect for a Rust project: SKILL.md gives Kilo the knowledge (your conventions, gotchas, build commands); subagents give you division of labor with constrained permissions (a read-only explorer can't accidentally edit code; a specialized reviewer only sees what it needs); Plan Mode gives you a checkpoint before changes are made. Together they reduce wasted tokens, prevent unwanted edits, and make behavior more predictable across a large or safety-sensitive codebase.

### Example Mode/Agent

Directory Structure :

	.kilo/
	├── agents/
	│   └── summarizer.md
	│
	└── skills/
	    └── summarizer-skill/
	        └── SKILL.md



summarizer.md :

	---
	description: Summarizes documents and technical content using the summarizer-skill.
	mode: subagent
	model: anthropic/claude-sonnet-4
	permission:
	  read: allow
	  write: deny
	  edit: deny
	  bash: deny
	color: "#8B5CF6"
	temperature: 0.2
	variant: summarizer
	hidden: false
	disable: false
	---
	
	# Summarizer Agent
	
	Use the `summarizer-skill` skill for all summarization tasks.
	
	## Steps
	
	1. Determine what the user wants summarized.
	2. Identify and read the relevant source material.
	3. Invoke and follow `summarizer-skill`.
	4. Produce the requested summary format.
	5. Verify that the summary accurately represents the source.
	6. Return the result without modifying project files.
	
	## Rules
	
	- Always use `summarizer-skill` when performing summarization.
	- Do not reproduce the skill's instructions here; use the skill itself.
	- Do not modify, create, or delete files.
	- Do not execute shell commands.
	- Do not invent information or citations.
	


### Another Example of Mode/Agent Usage


                    ┌──────────────────┐
                    │   Main Agent     │
                    │   / Orchestrator │   -----------------------> Agent, only it is written in it's instructions to use other agents.
                    └────────┬─────────┘
                             │
             ┌───────────────┼───────────────┐
             ▼               ▼               ▼
      ┌────────────┐  ┌────────────┐  ┌────────────┐
      │ Researcher │  │  Engineer  │  │  Reviewer  │--------------> Agent, it is written in their instructions to use skills.
      └─────┬──────┘  └─────┬──────┘  └─────┬──────┘
            │               │               │
        ┌───┴───┐       ┌───┴───┐       ┌───┴───┐
        ▼       ▼       ▼       ▼       ▼       ▼
      Search  Papers   Code   Tests   Critic  Editor --------------> Skill
      

      
      
	       
## How to Write Workflows (Commands) 

Command/Workflow -> Agent -> Skill

A good command/workflow file should answer:

- When should this command be used?
- What inputs does it accept?
- What exact steps should the agent follow?
- What constraints must it respect?
- What should the final output look like?
- How does it know it succeeded?


**Best practices :** 

**Separate workflow from policy:**

	## Workflow
	
	1. Inspect the existing implementation.
	2. Identify affected tests.
	3. Implement the change.
	4. Run the relevant tests.
	5. Run the formatter.
	6. Report the result.
	
	## Constraints
	
	- Do not modify public APIs unless explicitly requested.
	- Do not introduce new dependencies without approval.
	- Preserve backward compatibility.


**Give the agent decision rules :**
	
	## Test selection
	
	- If only `src/foo.ts` changes, run the tests covering `foo`.
	- If shared utilities change, run the entire unit-test suite.
	- If database schemas change, run migrations and integration tests.
	- If configuration affecting production changes, run the full validation suite.


**Explicitly distinguish inspection from modification :**
	
	## Phase 1 — Inspect
		
	Do not modify files during this phase.
	
	- Inspect the repository structure.
	- Read the relevant implementation.
	- Read existing tests.
	- Identify conventions used by neighboring code.
	
	## Phase 2 — Implement
	
	Only after understanding the existing implementation:

	- Modify the smallest necessary set of files.
	- Follow existing project conventions.


**Specify what "done" means :**
	
	## Definition of Done
	
	The task is complete only when:
	
	- The requested behavior is implemented.
	- Existing tests pass.
	- New behavior has test coverage.
	- Formatting and linting pass.
	- No unrelated files were modified.
	- The final response lists all modified files.


**Prefer deterministic commands :**
If you know the command, give it explicitly.

	Run:
	
	```bash
	pnpm lint
	pnpm test
	pnpm typecheck


**Tell the agent how to handle uncertainty :**
This prevents the agent from confidently inventing architecture.
	
	## Uncertainty
	
	If the requested behavior conflicts with an existing architectural constraint:
	
	1. Identify the conflict.
	2. Inspect existing patterns for precedent.
	3. Prefer the established project pattern.
	4. If no clear precedent exists, stop before making a potentially breaking architectural decision and report the ambiguity.
	


**Keep commands composable ( multiple files containing different parts ) :**

Instead of one enormous:

	.kilo/commands/develop-feature.md
	
Then each command has a focused responsibility:

	.kilo/
	└── commands/
	    ├── inspect.md
	    ├── implement.md
	    ├── test.md
	    ├── review.md
	    ├── refactor.md
	    └── release.md
	
Then each command has a focused responsibility.
For Example :

	# Review
	
	Review the current changes without modifying files.
	
	## Steps
	
	1. Inspect `git diff`.
	2. Check changed files against project conventions.
	3. Check for correctness issues.
	4. Check for missing tests.
	5. Check for unnecessary changes.
	6. Run relevant static checks.
	
	## Output
	
	Report findings grouped by severity:
	
	- Critical
	- High
	- Medium
	- Low
	- Informational
	
	Do not modify files.
	
That's substantially easier for an agent to follow than a 500-line "do everything" command.


**Don't duplicate global instructions (for example those written in AGENTS.md file) :**

If your project already has AGENTS.md don't copy all of that into every .kilo/commands/*.md.

**Use explicit "do not" constraints sparingly :**

Negative instructions are useful when there's a known failure mode:

	Do not modify generated files.
	Do not change the public API.
	Do not add dependencies.
	Do not commit changes.
	

**Make the final response part of the contract :**

For automated workflows, this is surprisingly important.
For example:

	## Final response
	
	Use this format:
	
	### Summary
	- ...
	
	### Files changed
	- `path/to/file`
	
	### Validation
	- `pnpm test` — passed
	- `pnpm lint` — passed
	
	### Notes
	- ...
	

Now downstream humans—or another automated process—get predictable output.

**Avoid putting too much prose into workflow files :**

A command file isn't the place for an essay about why the architecture exists.

Instead of:

	The reason we use repositories is that historically...

prefer:

	All database access must go through the repository layer.
	Do not access the ORM directly from services.


**References :**

	https://github.com/danielrosehill/Claude-Slash-Commands
	https://github.com/jqueryscript/Claude-Code-Slash-Commands-Cheatsheet
	https://github.com/hesreallyhim/awesome-claude-code
	https://github.com/wshobson/commands
	https://github.com/cassler/awesome-claude-code-setup


### Example Workflow(Command)


Directory Structure :

	.kilo/
	├── agents/
	│   └── summarizer.md
	│
	├── commands/
	│   └── summarization.md
	│
	└── skills/
	    └── summarizer-skill/
	        └── SKILL.md



summarization.md :

	---
	description: Summarize the text according to company conventions
	agent: code
	---
	
	# Summarize
	
	## Workflow
	
	1. Inspect the existing texts and their summaries in directory /data.
	2. Identify summarized text relation to the orginal text.
	3. Summarize the text.
	4. Review the summary according to the http://company-net/company-document-properties.md .
	5. Summarize the text again regarding the last review.
	6. Write it to a new file.
	

task delegation to an agent example, summarization.md :

	---
	description: Summarize the text according to company conventions
	agent: code
	---
	
	Delegate the implementation to `summarizer`.
	
	Provide the summarizer with:
	
	- The original user request.
	- The company standards documents in /data/standars directory.
	- Any relevant findings from repository inspection.
	
	The summarizer should:
	
	- Summarize the requested change.
	- Follow company conventions.
	- Make the smallest reasonable summary.
	- Avoid unrelated refactoring.


Summarization command (workflow) is callable as "/summarization" in the kilo command line. Summarization command calls agents, agents call skills. "agent:code" in the frontmatter header, you can set agent parameter as "code", which is default kilo's agent, or you may set to one of your custom agents, like "summarizer".



## How to Write MCPs 
 
There are already good guides on the web about this topic :

	https://modelcontextprotocol.io/docs/2026-07-28/getting-started/intro
	https://modelcontextprotocol.io/docs/2026-07-28/develop/build-server
	https://modelcontextprotocol.info/docs/tutorials/writing-effective-tools/
	


## Building Harness using Skills + Modes(Agents) + Workflows(Commands) + Memory + MCPs

We build a harness for our development environment.  We will use the following main parts in our development environment, so the harness will be built around them :

1. rust
2. gitea
3. kilo code

### Gitea Check List

1. If you did not already install rust-dev-env : checkout and install https://github.com/havelsan/rust-dev-env to ~/sdk directory
    -  source release file
    -  go to rust-dev-env/rust directory and run install.sh
    -  go to rust-dev-env/devops directory and run install.sh , also follow the instructions in README.md file in that directory to create example users , projects and organizations. Also creating PERSONAL ACCESS TOKEN is written in that README.md file.
    
2. Start the gitea if not already started :
    - cd ~/sdk/rust-dev-env/devops/bin; ./run_gitea.sh
    - This starts gitea at URL : "http://localhost:13000"

3. Gitea-mcp binary is also installed while installing gitea, you may also test it 
     - source ~/sdk/rust-dev-env/release
     - gitea-mcp -t stdio --host "http://localhost:13000" --token "7dcf5fa2452b48cbd4c91045996fc6e4e4115428"
           - We assume that the token in this command was generated in the first step by reading the devops/README.md 
           - After writing this command , we send following json messages and expect any response. If we obtain any response, gitea and mcp are working.
                 - {"jsonrpc":"2.0","id":1,"result":{"capabilities":{"tools":{}},"protocolVersion":"2024-11-05","serverInfo":{"name":"Gitea MCP Server","version":"1.8.0"}}}
                 - {"jsonrpc": "2.0", "method": "tools/list", "id": 1}
 
### Kilo Code Check List

1. Check the .config/kilo/kilo.jsonc file, this should be the same as $RUST_AGENT_INFRA_DIR/install/23.kilo.jsonc  file and should contain mcp part. 

2. Gitea-mcp test :
   - On the Gitea web interface as admin user :
        - Create a user in gitea (e.g. cargo-test-access) , 
        - create an organization that cargo-test-access acan write (e.g. cargo-test), 
        - create a repository in that organization (e.g. test-repo-01).
   - On the Gitea web interface as cargo-test-access user 
        - generate access token for that user ( settings > applications ) (e.g. 3e55118794c5ed85a2ce0bad8324ed501c36e604)
   - export GITEA_USER_PAT="3e55118794c5ed85a2ce0bad8324ed501c36e604" in terminal.
   - Run the kilo command in terminal.
   - Give the command : 'create an issue in the test-repo-01 with tiltle "NEW_TEST_ISSUE" and body "ISSUE BODY ABCD" and assign to to the cargo-test-access user '
   - After this command you shoud see "NEW_TEST_ISSUE" issue created under test-repo-01.

 
  
### Roles

| Role No | Role Name                             | Category               | Core Responsibility / Focus Area                                                                                                                                       |
| ------: | ------------------------------------- | ---------------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
|   **1** | Product Owner (Human)                 | Management             | Strategic direction, business value, priorities, requirements approval, and ultimate decision-making authority.                                                        |
|   **2** | Coordinator                           | Management             | Central coordination agent. Owns project-level workflow; communicates with the Product Owner and all agents through Gitea Issues; assigns, tracks, and escalates work. |
|   **3** | Business Analyst                      | Analysis               | Requirement engineering, business processes, domain rules, use cases, acceptance criteria, and requirement traceability.                                               |
|   **4** | Product Manager                       | Product                | Product vision, roadmap, feature prioritization, product strategy, and customer value.                                                                                 |
|   **5** | Project Manager                       | Management             | Project planning, milestones, dependencies, resources, schedules, risks, and delivery coordination.                                                                    |
|   **6** | System Architect                      | Architecture           | Macro-level system structure, technology selection, system boundaries, component relationships, and communication protocols.                                           |
|   **7** | Software Architect                    | Architecture           | Micro-level software architecture, design patterns, modularity, interfaces, dependency boundaries, and maintainability.                                                |
|   **8** | Solutions Architect                   | Architecture           | Translates business requirements into complete technical solutions and integrates application, infrastructure, data, and external systems.                             |
|   **9** | Network Engineer                      | Infrastructure         | Network topology, routing, protocols, DNS, firewalls, data transit, bandwidth, and latency optimization.                                                               |
|  **10** | System Administrator                  | Infrastructure         | Operating-system configuration, services/daemons, systemd, users, permissions, storage, processes, and server maintenance.                                             |
|  **11** | Cloud Engineer                        | Infrastructure         | Cloud resources, virtual networks, compute, storage, managed services, infrastructure configuration, and cloud optimization.                                           |
|  **12** | Platform Engineer                     | Infrastructure         | Internal developer platforms, reusable infrastructure, tooling, environments, deployment platforms, and developer experience.                                          |
|  **13** | DevOps Engineer                       | Operations             | CI/CD, build systems, deployment automation, infrastructure automation, Gitea management, release automation, and development tooling.                                 |
|  **14** | Site Reliability Engineer             | Operations             | Production reliability, observability, availability, incident response, capacity planning, SLOs/SLIs, and resilience.                                                  |
|  **15** | Software Development Engineer         | Development            | Direct filesystem/code implementation, algorithms, business logic, APIs, services, and application functionality.                                                      |
|  **16** | Frontend Developer                    | Development            | Web interfaces, client-side applications, UI implementation, state management, and frontend integration.                                                               |
|  **17** | Backend Developer                     | Development            | Backend services, APIs, business logic, databases, integrations, authentication, and server-side functionality.                                                        |
|  **18** | Full-Stack Developer                  | Development            | End-to-end implementation across frontend, backend, APIs, databases, and application integration.                                                                      |
|  **19** | Mobile Developer                      | Development            | iOS/Android applications, mobile UI, device APIs, mobile networking, and platform-specific functionality.                                                              |
|  **20** | Desktop Developer                     | Development            | Desktop applications, operating-system integration, native interfaces, packaging, and desktop-specific functionality.                                                  |
|  **21** | Embedded Systems Engineer             | Hardware / Development | Firmware, microcontrollers, real-time systems, hardware interfaces, device drivers, and embedded software.                                                             |
|  **22** | Machine Learning Engineer             | AI / Data              | ML pipelines, model implementation, training infrastructure, inference systems, evaluation, and model integration.                                                     |
|  **23** | AI Engineer                           | AI / Development       | AI-powered application features, LLM integration, agents, inference workflows, prompt/tool orchestration, and AI systems.                                              |
|  **24** | ML/AI Researcher                      | Science / AI           | Novel algorithms, model research, experimentation, evaluation methodology, and scientific investigation.                                                               |
|  **25** | Data Engineer                         | Data                   | Data pipelines, ETL/ELT, data infrastructure, data quality, warehouses, streaming, and data integration.                                                               |
|  **26** | Data Scientist                        | Data / Analytics       | Statistical analysis, predictive modeling, experimentation, data-driven insights, and quantitative decision support.                                                   |
|  **27** | Data Analyst                          | Data / Analytics       | Business/product analytics, dashboards, metrics, reporting, and exploratory analysis.                                                                                  |
|  **28** | Analytics Engineer                    | Data / Analytics       | Analytical data models, transformation pipelines, metric definitions, and analytics infrastructure.                                                                    |
|  **29** | Database Administrator                | Data                   | Database architecture, schema management, migrations, indexing, backups, permissions, performance, and query optimization.                                             |
|  **30** | Business Intelligence Engineer        | Data / Analytics       | BI systems, dashboards, reporting infrastructure, data visualization, and executive metrics.                                                                           |
|  **31** | Security Engineer                     | Security               | Threat modeling, security architecture, access control, vulnerability mitigation, security policies, and hardening.                                                    |
|  **32** | Application Security Engineer         | Security               | Secure software development, code security, dependency vulnerabilities, application threat modeling, and security testing.                                             |
|  **33** | Cloud Security Engineer               | Security               | Cloud security configuration, IAM, network security, secrets, policies, and cloud threat mitigation.                                                                   |
|  **34** | Cybersecurity Analyst                 | Security               | Security monitoring, investigation, vulnerability analysis, threat detection, and security incident analysis.                                                          |
|  **35** | Security Architect                    | Security               | Enterprise security architecture, trust boundaries, security controls, identity architecture, and defense-in-depth.                                                    |
|  **36** | Security Operations Engineer          | Security / Operations  | SOC workflows, security monitoring, alert handling, incident response automation, and threat detection infrastructure.                                                 |
|  **37** | Software Review Engineer              | Quality                | Code review, architecture adherence, coding standards, logical sanity checks, maintainability, and technical debt detection.                                           |
|  **38** | Software Quality Assurance Engineer   | Quality                | Test strategy, test planning, automation development, execution, validation, defect management, and quality gates.                                                     |
|  **39** | Software Test Development Engineer    | Testing                | Test frameworks, test harnesses, test infrastructure, fixtures, mocks, simulators, and automated testing systems.                                                      |
|  **40** | Software Testing Engineer             | Testing                | Test execution, behavioral validation, regression testing, exploratory testing, defect reproduction, and bug tracking.                                                 |
|  **41** | Performance Engineer                  | Quality / Performance  | Load testing, profiling, benchmarking, bottleneck analysis, scalability testing, and performance optimization.                                                         |
|  **42** | UX Designer                           | Design                 | User experience, interaction flows, information architecture, usability, and interaction design.                                                                       |
|  **43** | UI Designer                           | Design                 | Visual interfaces, layouts, components, typography, visual hierarchy, and design systems.                                                                              |
|  **44** | Product Designer                      | Design                 | End-to-end product design combining UX, UI, interaction, user needs, and product objectives.                                                                           |
|  **45** | UX Researcher                         | Research               | User interviews, usability studies, behavioral research, personas, user journeys, and evidence-based UX decisions.                                                     |
|  **46** | Psychologist                          | Cognitive / UX         | Cognitive load, human behavior, HCI principles, usability psychology, and human factors.                                                                               |
|  **47** | Documentation Engineer                | Documentation          | Technical documentation, architecture documentation, wiki maintenance, API references, tutorials, and knowledge management.                                            |
|  **48** | Technical Writer                      | Documentation          | Developer-facing and user-facing documentation, guides, manuals, release documentation, and technical communication.                                                   |
|  **49** | Mathematician                         | Science / Theory       | Formal proofs, mathematical modeling, numerical methods, algorithmic complexity, optimization, and mathematical validation.                                            |
|  **50** | Physicist                             | Science / Theory       | Physics-based modeling, simulations, kinematics, thermodynamics, wave propagation, and physical-system validation.                                                     |
|  **51** | Chemist                               | Science / Theory       | Molecular interactions, chemical models, material properties, reaction kinetics, and chemistry-domain validation.                                                      |
|  **52** | Biologist                             | Science / Domain       | Biological models, bioinformatics, cellular processes, biological data interpretation, and organic-system modeling.                                                    |
|  **53** | Medical Doctor                        | Health / Domain        | Clinical knowledge, medical terminology, safety thresholds, clinical guidelines, and healthcare-domain validation.                                                     |
|  **54** | Mechanical Engineer                   | Engineering            | Mechanical systems, mechanisms, stress analysis, CAD parameters, materials, and kinematic assemblies.                                                                  |
|  **55** | Civil Engineer                        | Engineering            | Structural systems, spatial layouts, foundations, static loads, construction constraints, and civil engineering analysis.                                              |
|  **56** | Electronics Engineer                  | Hardware               | Circuit design, electronics, signal processing, sensors, PCB-level considerations, and hardware/software co-design.                                                    |
|  **57** | Computer Hardware Engineer            | Hardware               | CPU architecture, memory hierarchy, buses, peripherals, hardware architecture, and low-level computing systems.                                                        |
|  **58** | Philosopher                           | Ethics / Logic         | Ethical reasoning, epistemology, argument consistency, assumptions, value conflicts, and decision justification.                                                       |
|  **59** | Product Marketing Manager             | Marketing              | Product positioning, messaging, market segmentation, competitive positioning, and product launches.                                                                    |
|  **60** | Growth Marketer                       | Marketing              | Acquisition, activation, conversion, retention, experimentation, growth metrics, and growth strategy.                                                                  |
|  **61** | Content / SEO Specialist              | Marketing              | Content strategy, technical content, SEO, search visibility, keyword strategy, and content optimization.                                                               |
|  **62** | Sales Engineer / Solutions Consultant | Sales / Technical      | Technical customer discovery, solution demonstrations, architecture proposals, proof-of-concepts, and technical sales support.                                         |
|  **63** | Business Development Manager          | Business               | Partnerships, business opportunities, strategic relationships, and new-market development.                                                                             |
|  **64** | Account Manager                       | Customer / Sales       | Customer relationship management, account health, renewals, expansion opportunities, and communication.                                                                |
|  **65** | Customer Success Manager              | Customer               | Customer onboarding, adoption, customer outcomes, feedback, retention, and success planning.                                                                           |
|  **66** | Technical Support Engineer            | Support                | Technical troubleshooting, issue reproduction, diagnostics, customer support, and escalation to engineering.                                                           |
|  **67** | Customer Support Specialist           | Support                | User support, issue intake, FAQs, ticket management, and customer communication.                                                                                       |
|  **68** | Implementation Specialist             | Customer / Technical   | Customer-specific configuration, deployment, integration, onboarding, and implementation support.                                                                      |
|  **69** | IT Support Engineer                   | IT                     | Internal user support, workstation configuration, software installation, access management, and IT troubleshooting.                                                    |
|  **70** | IT Manager                            | IT / Management        | Internal IT infrastructure, IT policies, support operations, hardware/software assets, and internal systems.                                                           |
|  **71** | Internal Tools Engineer               | IT / Development       | Internal applications, automation tools, developer tools, administrative systems, and productivity infrastructure.                                                     |
|  **72** | Accountant                            | Finance                | Accounting records, financial transactions, reconciliation, financial reporting, and accounting compliance.                                                            |
|  **73** | Financial Analyst                     | Finance                | Financial modeling, budgeting, forecasting, cost analysis, and financial decision support.                                                                             |
|  **74** | Finance Manager / CFO                 | Finance / Management   | Financial strategy, budgeting, financial controls, investment decisions, and organizational financial management.                                                      |
|  **75** | HR / People Operations                | People / Management    | Hiring processes, employee operations, organizational policies, performance processes, and people management.                                                          |
|  **76** | Recruiter / Talent Acquisition        | People                 | Candidate sourcing, technical recruitment, interviews, hiring pipelines, and workforce planning.                                                                       |
|  **77** | Legal Counsel                         | Legal                  | Contracts, intellectual property, legal risk, licensing, terms, and legal compliance.                                                                                  |
|  **78** | Compliance Engineer                   | Compliance             | Regulatory requirements, compliance controls, audit evidence, policies, and compliance verification.                                                                   |
|  **79** | Operations Manager                    | Operations             | Organizational operations, process optimization, coordination, resources, and operational efficiency.                                                                  |
|  **80** | Release Manager                       | Operations / Quality   | Release planning, release coordination, versioning, release readiness, deployment approvals, and rollback coordination.                                                |
|  **81** | Incident Manager                      | Operations             | Production incident coordination, escalation, communication, resolution tracking, and post-incident reviews.                                                           |
|  **82** | Configuration Manager                 | Operations             | Configuration baselines, environment consistency, version control, configuration tracking, and change control.                                                         |

 
### Agent Command Catalog (Rust, Gitea-driven)

Every command also accepts the global parameters: `[--target] [--scope module/crate/workspace/system] [--depth quick/standard/thorough] [--roles +N,-N] [--gates po,review,qa,security,none] [--priority p0..p3] [--milestone] [--input] [--output] [--budget] [--parent #issue] [--dry-run]`.
Syntax: `<x>` required, `[x]` optional, `a/b` choose one. Agents run left to right (`→`); `/` inside an agent cell means "pick one as needed".

| # | Category | Command | Parameters | Agents (in order) | Output |
|--:|---|---|---|---|---|
| 1 | Core | `/init-project` | `<name> [--layout workspace/single] [--ci gitea-actions] [--license]` | 2 TL → 7 SwArch → 12 Platform → 13 DevOps → 82 ConfigMgr | Cargo workspace, repo layout, CI skeleton, ADR folder, issue and label templates |
| 2 | Core | `/intake-requirement` | `<title> [--source po/customer/support] [--req-id]` | 1 PO → 3 BA → 4 PdM → 2 TL | Requirement doc, acceptance criteria, traceability IDs (PO approval) |
| 3 | Core | `/plan-roadmap` | `[--horizon quarter/year] [--themes] [--capacity]` | 4 PdM → 3 BA → 5 PjM → 73 FinAnalyst | Roadmap, milestones, dependency map, risk register (PO approval) |
| 4 | Core | `/decompose-epic` | `<epic#> [--max-issues] [--granularity story/task]` | 2 TL → 7 SwArch → 5 PjM | Child issues with owners, estimates, dependencies |
| 5 | Core | `/design-feature` | `<req-id> [--ui yes/no] [--threat-model yes/no]` | 3 BA → 6 SysArch/7 SwArch → 42 UXD → 31 SecEng | Design doc, ADR, threat-model notes |
| 6 | Core | `/implement-task` | `<issue#> [--role sde/be/fe/desktop] [--tests unit/unit+integration]` | 15 SDE/17 BE/16 FE/20 Desktop → 39 TestDev | Code, unit tests, PR |
| 7 | Core | `/review-pr` | `<pr#> [--focus arch/style/security/perf]` | 37 Review → 32 AppSec → 41 Perf | Review verdict, blockers filed as issues |
| 8 | Core | `/test-cycle` | `<milestone> [--types unit/integration/e2e/regression]` | 38 QA → 39 TestDev → 40 Tester | Test plan, automated suite, defect issues |
| 9 | Core | `/bugfix` | `<bug#> [--severity s1..s4] [--regression-test yes/no]` | 40 Tester → 15 SDE → 37 Review → 38 QA | Reproduction, fix, regression test |
| 10 | Core | `/hotfix` | `<incident#> --version <semver> [--rollback-plan]` | 81 IncidentMgr → 14 SRE → 15 SDE → 80 ReleaseMgr | Patch release and rollback plan |
| 11 | Core | `/release` | `--version <semver> [--channel stable/rc/nightly] [--rollout canary:N%/full] [--rollback-on slo-breach]` | 80 ReleaseMgr → 13 DevOps → 82 ConfigMgr → 47 DocEng → 48 TechWriter | Tagged release, changelog, signed artifacts (PO approval) |
| 12 | Core | `/spike` | `<question> [--timebox 2d] [--domain math/physics/ml/arch]` | 24 Researcher/49 Math/50 Phys → 15 SDE | Research note and recommendation |
| 13 | Core | `/refactor-debt` | `<crate/module> [--goal readability/perf/modularity] [--behavior-lock yes]` | 37 Review → 7 SwArch → 15 SDE → 38 QA | Debt report, refactor PRs, behavior-unchanged proof |
| 14 | Core | `/status-report` | `[--period week/sprint/milestone] [--audience po/team]` | 2 TL → 5 PjM | Progress, blockers, risks |
| 15 | Java→Rust | `/assess-legacy` | `<java-repo> [--build maven/gradle] [--include-db] [--include-jni]` | 7 SwArch → 8 SolArch → 37 Review → 29 DBA → 32 AppSec | Inventory, dependency graph, debt, module classification (port/rewrite/retire) |
| 16 | Java→Rust | `/recover-domain` | `<module/all> [--from code/db/docs/runtime]` | 3 BA → 7 SwArch → 29 DBA | Business rules, domain model, ER model (PO approval) |
| 17 | Java→Rust | `/capture-behavior` | `<module> [--method golden/contract/db-diff] [--env <url>]` | 39 TestDev → 40 Tester → 38 QA | Characterization tests against the running Java system |
| 18 | Java→Rust | `/ux-audit-legacy` | `<app> [--journeys <list>] [--personas]` | 45 UXR → 46 Psych → 42 UXD → 3 BA | User journeys, pain points, cognitive-load findings |
| 19 | Java→Rust | `/redesign-ux` | `<app> [--design-system new/existing] [--platform web/desktop/mobile] [--usability-test]` | 42 UXD → 43 UID → 44 ProdDes → 46 Psych → 45 UXR | New flows, design system, prototype spec (PO approval) |
| 20 | Java→Rust | `/design-target` | `<system> [--async tokio/sync] [--api axum/tonic] [--db sqlx/diesel] [--ui leptos/egui/iced/tauri]` | 6 SysArch → 7 SwArch → 8 SolArch → 31 SecEng → 35 SecArch | Rust target architecture, crate boundaries, ADRs (PO approval) |
| 21 | Java→Rust | `/plan-migration` | `<system> [--strategy strangler/big-bang/rewrite] [--order <modules>] [--flags]` | 5 PjM → 2 TL → 7 SwArch | Module order, interop plan, feature-flag and rollback plan |
| 22 | Java→Rust | `/build-bridge` | `<module> [--kind http/grpc/jni-rs] [--direction java-to-rust/rust-to-java/both]` | 15 SDE → 17 BE → 12 Platform | Temporary interop layer so Java and Rust coexist |
| 23 | Java→Rust | `/port-module` | `<module> --from java:<path> --to rust:<crate> [--strategy strangler/rewrite] [--api-compat strict/relaxed] [--parity-tests <suite>] [--ui keep/redesign]` | 15 SDE/17 BE → 37 Review → 39 TestDev | Idiomatic Rust module passing the characterization tests |
| 24 | Java→Rust | `/migrate-data` | `--source <db-uri> --dest <db-uri> [--mode dual-write/backfill/snapshot] [--verify checksum/row-diff]` | 29 DBA → 25 DataEng → 17 BE | Migration scripts, backfill, reconciliation report |
| 25 | Java→Rust | `/build-ui` | `--design <spec.md> --stack leptos/yew/egui/iced/tauri [--platform web/desktop]` | 16 FE/20 Desktop/18 FullStack → 43 UID → 42 UXD | UI implemented against the new design system |
| 26 | Java→Rust | `/parity-test` | `<module> [--mode shadow-traffic/replay/batch] [--tolerance] [--duration]` | 38 QA → 40 Tester → 39 TestDev | Old-versus-new diff report |
| 27 | Java→Rust | `/perf-compare` | `--baseline <ref> --candidate <ref> [--metrics latency,throughput,memory,startup] [--regress-limit 5%]` | 41 Perf → 14 SRE | Benchmark comparison, Java versus Rust |
| 28 | Java→Rust | `/security-hardening` | `<module> [--checks unsafe,deps,authn,authz]` | 31 SecEng → 32 AppSec → 33 CloudSec | Hardening report and fix issues |
| 29 | Java→Rust | `/cutover-module` | `<module> [--rollout canary:N%/full] [--slo <name>] [--rollback-on]` | 80 ReleaseMgr → 14 SRE → 13 DevOps → 81 IncidentMgr | Canary rollout, SLO watch, go/no-go (PO approval) |
| 30 | Java→Rust | `/decommission-legacy` | `<service> [--archive-db yes/no] [--archive-docs yes/no]` | 10 SysAdmin → 13 DevOps → 29 DBA → 47 DocEng | Retired Java service, archived data and docs |
| 31 | Java→Rust | `/train-and-document` | `<system> [--audience dev/user/ops] [--format md/pdf]` | 47 DocEng → 48 TechWriter → 65 CSM | Migration guide, manuals, onboarding material |
| 32 | Physics | `/define-physics-model` | `<phenomenon> [--equations <file>] [--units si] [--validity-range]` | 50 Phys → 49 Math → 3 BA | Model spec with equations, assumptions, units (PO approval) |
| 33 | Physics | `/select-numerics` | `<model> [--candidates rk4,symplectic,implicit,fem,fvm] [--stability-analysis]` | 49 Math → 50 Phys → 24 Researcher → 7 SwArch | Method choice with stability and error analysis |
| 34 | Physics | `/design-sim-architecture` | `<model> [--layout ecs/soa] [--parallel rayon/none] [--gpu wgpu/cuda/none]` | 7 SwArch → 6 SysArch → 57 HW → 41 Perf | Crate layout, data layout, parallelism and GPU strategy |
| 35 | Physics | `/scaffold-workspace` | `<project> [--crates core-math,physics,solver,io,viz,cli] [--units uom/nalgebra]` | 15 SDE → 12 Platform → 13 DevOps | Workspace with crate skeletons and a units layer |
| 36 | Physics | `/implement-solver` | `<module> --model <spec.md> [--method rk4/symplectic/implicit] [--tolerance 1e-8] [--backend cpu/rayon/gpu] [--precision f32/f64]` | 15 SDE → 49 Math → 50 Phys | Solver implementation with physics and math review |
| 37 | Physics | `/verify-numerics` | `<module> [--tests mms,convergence,conservation,property] [--order <expected>]` | 49 Math → 39 TestDev → 38 QA | Convergence-order and conservation test suite |
| 38 | Physics | `/validate-physics` | `--against <dataset/analytic/paper> [--metric l2/linf/energy-drift] [--threshold 1e-3] [--experts 51,54,55,56]` | 50 Phys → 54 Mech/55 Civil/56 Elec/51 Chem → 40 Tester | Validation report (PO approval) |
| 39 | Physics | `/ensure-determinism` | `<module> [--across threads,platforms,builds] [--fp-policy strict/relaxed]` | 15 SDE → 41 Perf → 39 TestDev | Reproducibility tests and floating-point policy |
| 40 | Physics | `/optimize-sim` | `<module> [--tools perf,flamegraph] [--target simd/cache/gpu] [--bench-gate]` | 41 Perf → 57 HW → 15 SDE | Optimized code, benchmark gates |
| 41 | Physics | `/build-viz` | `<sim> [--stack bevy/wgpu/egui] [--mode realtime/offline] [--plots]` | 16 FE/20 Desktop → 43 UID → 42 UXD | Scientist-oriented visualization UI |
| 42 | Physics | `/build-io-pipeline` | `<sim> [--formats hdf5,parquet,json] [--scenario-config toml/yaml]` | 25 DataEng → 17 BE → 15 SDE | Scenario input and result output pipeline |
| 43 | Physics | `/regression-baseline` | `<sim> [--tolerance-rule abs/rel] [--ref-data <dir>]` | 39 TestDev → 38 QA → 82 ConfigMgr | Golden-result store with versioned reference data |
| 44 | Physics | `/scale-test` | `<sim> [--cores N] [--nodes N] [--size-range]` | 41 Perf → 14 SRE → 11 Cloud | Scaling curves and bottleneck report |
| 45 | Physics | `/document-model` | `<sim> [--parts theory,api,validation,tutorial]` | 47 DocEng → 48 TechWriter → 50 Phys | Theory manual, API docs, validation report, tutorials |
| 46 | Physics | `/verify-structural-model` | `<model> [--loads static/dynamic] [--code <standard>]` | 55 Civil → 49 Math → 50 Phys | Structural model verification |
| 47 | Physics | `/hardware-software-codesign` | `<device> [--mcu <name>] [--interfaces spi,i2c,can]` | 56 Elec → 57 HW → 21 Embedded → 15 SDE | Hardware/software partition and interface spec |
| 48 | Quality / Security | `/threat-model` | `<component> [--method stride/attack-tree] [--trust-boundary]` | 31 SecEng → 35 SecArch → 32 AppSec → 6 SysArch | Threat model and mitigation issues |
| 49 | Quality / Security | `/dependency-audit` | `[--tools cargo-audit,cargo-deny] [--licenses allow-list]` | 32 AppSec → 77 Legal | Vulnerability and license report |
| 50 | Quality / Security | `/unsafe-audit` | `<crate> [--tools miri,cargo-geiger]` | 32 AppSec → 37 Review → 57 HW | Soundness review of every `unsafe` block |
| 51 | Quality / Security | `/fuzz-campaign` | `--target <fn/parser> [--duration 4h] [--corpus <dir>]` | 39 TestDev → 32 AppSec | Fuzz targets, crash triage |
| 52 | Quality / Security | `/perf-regression` | `<crate> [--bench criterion] [--threshold 5%]` | 41 Perf → 39 TestDev | Benchmarks in CI with threshold gates |
| 53 | Quality / Security | `/coverage-gap` | `[--tool llvm-cov] [--min 80%]` | 38 QA → 39 TestDev | Coverage report and missing-test issues |
| 54 | Quality / Security | `/concurrency-review` | `<crate> [--tools loom] [--focus deadlock/race]` | 7 SwArch → 37 Review → 15 SDE | Race and deadlock review, loom tests |
| 55 | Quality / Security | `/pen-test` | `<service> [--scope external/internal] [--rules-of-engagement]` | 34 SecAnalyst → 31 SecEng → 36 SecOps | Findings and fix plan |
| 56 | Infra / Ops | `/setup-ci` | `[--pipeline build,test,lint,audit,release] [--runners]` | 13 DevOps → 12 Platform → 82 ConfigMgr | Gitea Actions pipeline |
| 57 | Infra / Ops | `/containerize` | `<service> [--base distroless/scratch/ubuntu] [--static yes/no]` | 13 DevOps → 10 SysAdmin → 12 Platform | Minimal reproducible images |
| 58 | Infra / Ops | `/provision-env` | `<env dev/staging/prod> [--cloud <provider>] [--network <topology>]` | 11 Cloud → 9 Network → 10 SysAdmin → 33 CloudSec | Environment defined as code |
| 59 | Infra / Ops | `/deploy` | `<service> --env <env> [--strategy rolling/blue-green/canary]` | 13 DevOps → 80 ReleaseMgr → 14 SRE | Deployment with rollback path |
| 60 | Infra / Ops | `/define-slo` | `<service> [--slis latency,availability,error-rate] [--targets]` | 14 SRE → 4 PdM → 5 PjM | SLIs, SLOs, dashboards, alerts |
| 61 | Infra / Ops | `/incident` | `<alert/issue> [--severity sev1..sev4] [--comms-channel]` | 81 IncidentMgr → 14 SRE → 15 SDE → 66 TSE | Triage, mitigation, communication |
| 62 | Infra / Ops | `/postmortem` | `<incident#> [--blameless yes]` | 81 IncidentMgr → 14 SRE → 2 TL → 58 Phil | Review and action items with owners |
| 63 | Infra / Ops | `/capacity-plan` | `<service> [--horizon 6m/1y] [--growth-model]` | 14 SRE → 41 Perf → 73 FinAnalyst | Forecast and cost model |
| 64 | Infra / Ops | `/db-change` | `<migration> [--type schema/index/backup/permission] [--online yes/no]` | 29 DBA → 17 BE → 38 QA | Reviewed migration with backup and rollback |
| 65 | Infra / Ops | `/env-drift-check` | `[--env <name>] [--baseline <tag>]` | 82 ConfigMgr → 13 DevOps | Drift report against the configuration baseline |
| 66 | Business | `/compliance-check` | `<standard> [--controls <list>] [--evidence-dir <path>]` | 78 Compliance → 77 Legal → 31 SecEng → 47 DocEng | Control mapping and audit evidence |
| 67 | Business | `/license-review` | `[--policy <file>] [--include-transitive]` | 77 Legal → 32 AppSec | License compatibility report |
| 68 | Business | `/launch-plan` | `<product/version> [--segments] [--channels]` | 59 PMM → 60 Growth → 61 SEO → 4 PdM | Positioning, messaging, launch checklist |
| 69 | Business | `/customer-demo` | `<customer> [--scenario <file>] [--poc yes/no]` | 62 SalesEng → 15 SDE → 47 DocEng | Demo scenario, PoC, architecture proposal |
| 70 | Business | `/customer-onboarding` | `<customer> [--config <file>] [--integrations]` | 68 Impl → 65 CSM → 48 TechWriter | Customer configuration and onboarding guide |
| 71 | Business | `/support-escalation` | `<ticket#> [--logs <path>]` | 67 Support → 66 TSE → 40 Tester → 15 SDE | Reproduction and bug issue with logs |
| 72 | Business | `/feedback-loop` | `[--sources tickets,surveys,usage] [--period]` | 65 CSM → 27 DA → 45 UXR → 4 PdM | Insights feeding the next `/plan-roadmap` |
| 73 | Business | `/budget-review` | `[--period quarter/year] [--include cloud,compute,headcount]` | 73 FinAnalyst → 74 CFO → 5 PjM | Cost versus plan and forecast |
| 74 | Business | `/hiring-plan` | `<team> [--roles <list>] [--headcount N]` | 75 HR → 76 Recruiter → 2 TL | Role needs and interview kits |
| 75 | Meta | `/escalate` | `<issue#> [--options N]` | any → 2 TL → 1 PO | Blocked issue raised to the Product Owner with options |
| 76 | Meta | `/arbitrate-design` | `<adr#> [--criteria <list>]` | 6 SysArch → 7 SwArch → 8 SolArch → 58 Phil | Conflict resolved and recorded as an ADR |
| 77 | Meta | `/knowledge-sync` | `[--since <tag>] [--targets wiki,adr,api-docs]` | 47 DocEng → 71 InternalTools | Wiki and ADRs updated from merged PRs |
| 78 | Meta | `/retro` | `<sprint/milestone>` | 2 TL → 5 PjM → 79 OpsMgr | Retrospective and process improvements |
| 79 | Meta | `/agent-audit` | `[--period] [--roles <list>]` | 2 TL → 37 Review | Weak-output analysis and skill-file tuning proposals |
| 80 | Mobile / Embedded | `/build-mobile-app` | `<app> [--platform ios/android/both] [--core rust-uniffi/tauri-mobile]` | 19 Mobile → 43 UID → 42 UXD → 38 QA | Shared Rust core with native UI shells |
| 81 | Mobile / Embedded | `/build-firmware` | `<device> [--mcu <name>] [--runtime embassy/rtic] [--hil-tests]` | 21 Embedded → 56 Elec → 57 HW → 39 TestDev | `no_std` firmware with hardware-in-the-loop tests |
| 82 | Mobile / Embedded | `/port-to-embedded` | `<crate> --target <triple> [--no-std] [--mem-budget]` | 21 Embedded → 15 SDE → 41 Perf | Library ported to a constrained device |
| 83 | AI / ML | `/build-ml-pipeline` | `<model> [--framework burn/candle/onnx] [--stages train,eval,serve]` | 22 MLE → 25 DataEng → 26 DS → 41 Perf | Training, evaluation, and inference pipeline |
| 84 | AI / ML | `/add-ai-feature` | `<feature> [--llm <provider>] [--tools <list>] [--eval-set]` | 23 AIE → 7 SwArch → 31 SecEng → 38 QA | AI feature with tool orchestration and prompt evaluation |
| 85 | AI / ML | `/ai-safety-review` | `<feature> [--risks misuse,leakage,bias]` | 31 SecEng → 58 Phil → 23 AIE | Safety review and mitigation issues |
| 86 | Data / Analytics | `/analyze-experiment` | `<experiment> [--method ab/bayesian] [--metric]` | 26 DS → 27 DA → 4 PdM | Statistical analysis and recommendation |
| 87 | Data / Analytics | `/define-metrics` | `<domain> [--layer raw/staging/mart] [--engine polars/datafusion]` | 28 AnalyticsEng → 25 DataEng → 27 DA | Metric definitions and transformation models |
| 88 | Data / Analytics | `/build-dashboard` | `<audience> [--metrics <list>] [--refresh]` | 30 BI → 28 AnalyticsEng → 74 CFO | Executive dashboards and reporting |
| 89 | Domain science | `/validate-bio-model` | `<model> --against <dataset> [--metric]` | 52 Bio → 49 Math → 40 Tester | Biological model validation report |
| 90 | Domain science | `/clinical-safety-review` | `<feature> [--guideline <ref>] [--thresholds]` | 53 MD → 78 Compliance → 31 SecEng | Clinical terminology and safety-threshold check |
| 91 | Business | `/evaluate-partnership` | `<partner> [--integration-type api/data/oem]` | 63 BizDev → 4 PdM → 77 Legal → 8 SolArch | Opportunity assessment with technical feasibility |
| 92 | Business | `/account-review` | `<customer> [--period] [--renewal-date]` | 64 AcctMgr → 65 CSM → 62 SalesEng | Account health, renewal and expansion plan |
| 93 | Business | `/close-period` | `<month/quarter> [--allocate cloud,compute]` | 72 Accountant → 73 FinAnalyst → 74 CFO | Reconciliation, financial report, cost allocation |
| 94 | IT | `/onboard-employee-env` | `<person/team> [--toolchain rust,git,docker] [--access <groups>]` | 69 ITSupport → 10 SysAdmin → 71 InternalTools | Workstation setup, access, toolchain |
| 95 | IT | `/it-policy-review` | `[--areas access,assets,policies]` | 70 ITMgr → 31 SecEng → 78 Compliance → 82 ConfigMgr | Policy, asset, and access review |



### Agent Skills Catalog (Rust, Gitea-driven)

Each skill is a `skill.md` that agents load, with a matching helper script. Conventions: scripts live in `.agents/scripts/`, read the Gitea token and project settings from environment variables, print JSON to stdout, return a non-zero exit code on failure, and support `--dry-run`. Agent numbers refer to the 82-role table; `ALL` means every role.

| Skill No | Skill Name | Used by Agents | Skill Description | Script Description |
|--:|---|---|---|---|
| 1 | `gitea-issue-management` | ALL (1–82) | Create, comment on, label, assign, link and close Gitea issues using the project label scheme (role:N, phase:x, gate:y). Gitea issues are the only communication channel between agents. | `gitea_issue.sh` wraps the Gitea REST API (create, comment, label, assign, close, list); reads the token from env and prints the issue JSON |
| 2 | `role-handoff-protocol` | ALL (1–82) | Write a structured handoff comment (inputs consumed, artifacts produced, status, open questions, next role) so the next agent can start without re-reading the thread. | `handoff.py` posts the handoff block, sets the next-role label, and fails if a declared artifact path is missing |
| 3 | `command-parsing-dispatch` | 2 | Validate a command and its parameters against the schema, merge defaults, policy file and overrides, and resolve the role chain. | `parse_command.py` validates args against a JSON schema, merges `.agents/policy.toml`, and emits the epic YAML |
| 4 | `epic-decomposition` | 2, 5, 7 | Break an epic into child issues with owners, estimates, dependencies and acceptance criteria. | `decompose_epic.py` creates child issues from templates and links them as blockers or dependents |
| 5 | `approval-gate-management` | 1, 2, 80 | Enforce review, QA, security, release and Product Owner gates before an issue can close or a PR can merge. | `gate_check.py` checks required labels and approvals on an issue or PR and returns pass or fail with the missing gates |
| 6 | `escalation-handling` | 1, 2 | Summarize a blocker with options and a recommendation for the Product Owner, and track the decision. | `escalate.py` builds the options summary, assigns the issue to the PO, and records the decision when the PO replies |
| 7 | `status-reporting` | 2, 5, 79 | Aggregate progress, blockers, risks and milestone health into a short report. | `status_report.py` queries Gitea issues and milestones and renders a markdown report |
| 8 | `dependency-and-critical-path-planning` | 5, 2, 4 | Model task dependencies, find the critical path, and flag schedule risk. | `plan_graph.py` builds a DAG from issue links, computes the critical path, and outputs a Mermaid Gantt chart |
| 9 | `risk-register-management` | 5, 2, 74 | Identify, score, track and mitigate project risks. | `risk_log.py` appends and updates risks (probability, impact, owner, mitigation) in a versioned file and lists the top risks |
| 10 | `retrospective-and-process-metrics` | 79, 2, 5 | Measure cycle time, lead time and rework, run retrospectives, and propose process changes. | `process_metrics.py` computes cycle and lead times and reopen rates from Gitea history |
| 11 | `requirements-engineering` | 3, 4, 1 | Elicit, structure and version requirements with unique IDs, priorities and traceability to design, tests and issues. | `req_trace.py` assigns REQ IDs, links them to issues and tests, and reports untested or orphaned requirements |
| 12 | `acceptance-criteria-writing` | 3, 38, 40 | Write testable acceptance criteria in Given/When/Then form. | `gherkin_lint.sh` lints feature files and checks that each criterion maps to a REQ ID |
| 13 | `domain-model-recovery` | 3, 7, 29 | Extract business rules, entities and processes from code, schemas and runtime behavior into a domain model. | `extract_domain.py` builds an entity and rule inventory from source and DB schema and drafts a Mermaid ER diagram |
| 14 | `roadmap-prioritization` | 4, 5, 73 | Prioritize features and shape the roadmap with a transparent scoring model tied to customer value and cost. | `score_backlog.py` scores issues (RICE or WSJF) and outputs a ranked backlog |
| 15 | `feedback-synthesis` | 4, 45, 65, 27 | Combine tickets, surveys, interviews and usage data into themes that feed the roadmap. | `feedback_themes.py` clusters feedback text, counts themes, and links representative issues |
| 16 | `adr-authoring` | 6, 7, 8, 35, 58 | Record each architecture decision with context, options, trade-offs and consequences, and check the reasoning for hidden assumptions. | `new_adr.sh` creates a numbered ADR from a template, sets its status, and updates the ADR index |
| 17 | `rust-crate-architecture` | 6, 7, 15 | Design the workspace layout: crate boundaries, layering, visibility, feature flags and dependency direction. | `crate_graph.sh` runs `cargo metadata`, draws the crate graph, and flags cycles and layer violations |
| 18 | `interface-and-api-design` | 7, 8, 17 | Design stable interfaces and contracts (traits, REST via OpenAPI, gRPC via protobuf) with versioning rules. | `api_lint.sh` lints OpenAPI and proto files and checks for breaking changes against the previous version |
| 19 | `system-diagramming` | 6, 8, 9, 7 | Produce context, container, component and deployment diagrams as code. | `render_diagram.sh` renders Mermaid, PlantUML or D2 sources to SVG and checks that referenced components exist |
| 20 | `technology-selection` | 6, 8, 24, 12 | Compare technologies against weighted criteria and select with documented rationale (Rust crates, databases, protocols, platforms). | `tech_matrix.py` scores options against weighted criteria and outputs a comparison table |
| 21 | `solution-integration-design` | 8, 17, 25 | Design how application, data, infrastructure and external systems fit together end to end. | `integration_map.py` generates a system-interface inventory and a data-flow diagram from declared connectors |
| 22 | `legacy-java-analysis` | 7, 8, 37, 3, 29 | Inventory a Java code base: modules, dependencies, frameworks, JNI and native code, dead code, and hot spots. | `java_inventory.py` parses Maven or Gradle files and the class graph and emits a JSON inventory with coupling metrics |
| 23 | `java-to-rust-mapping` | 7, 15, 17 | Define idiomatic Rust equivalents for Java constructs (classes to structs and traits, exceptions to `Result`, GC patterns to ownership). | `scaffold_port.py` generates Rust module skeletons and TODO notes from Java signatures using a mapping table |
| 24 | `interop-bridge-design` | 7, 15, 17 | Design and build temporary Java and Rust coexistence layers (HTTP, gRPC, JNI via `jni-rs`, or C ABI via `cbindgen`). | `ffi_check.sh` generates headers or bindings and checks ABI and signature drift between the two sides |
| 25 | `strangler-migration-planning` | 5, 7, 8, 2 | Plan incremental migration: module ordering, feature flags, rollback points and cutover criteria. | `migration_plan.py` orders modules by coupling and risk and creates the migration epic with per-module issues |
| 26 | `network-diagnostics` | 9, 66, 10 | Diagnose DNS, routing, latency, bandwidth and connectivity problems. | `net_probe.sh` runs DNS, ping, traceroute and TCP checks and outputs timing and failure JSON |
| 27 | `firewall-and-dns-configuration` | 9, 31, 33 | Design and review firewall rules, DNS zones and segmentation. | `fw_plan.sh` generates nftables rules or cloud security-group diffs in dry-run mode for review |
| 28 | `linux-administration` | 10, 69, 12 | Configure and maintain OS services, users, permissions, storage and processes. | `sysaudit.sh` reports failed units, disk usage, users, permissions and open ports |
| 29 | `systemd-service-management` | 10, 13, 14 | Package and run Rust services under systemd with sandboxing, restarts and resource limits. | `gen_unit.sh` generates a hardened unit file and validates it with `systemd-analyze verify` |
| 30 | `cloud-infrastructure-as-code` | 11, 33, 12 | Define cloud networks, compute, storage and managed services declaratively with policy checks. | `iac_plan.sh` runs OpenTofu or Terraform validate and plan, then policy and cost checks, and posts the plan to the issue |
| 31 | `cloud-cost-allocation` | 11, 73, 72 | Attribute cloud and compute costs to products and teams and find savings. | `cost_report.py` pulls billing exports and groups spend by tag, service and project |
| 32 | `platform-environment-templates` | 12, 13, 71 | Provide reusable dev and CI environments, scaffolds and golden paths. | `env_up.sh` brings up a devcontainer or compose environment with the Rust toolchain and cached builds |
| 33 | `ci-pipeline-authoring` | 13, 12 | Write and maintain Gitea Actions pipelines: build, test, lint, audit, release. | `gen_workflow.py` generates workflow YAML from a policy file and validates it before commit |
| 34 | `container-image-build` | 13, 10, 12 | Build small, reproducible, static Rust images with SBOMs and provenance. | `build_image.sh` builds a musl or distroless image, generates an SBOM, and reports image size and layers |
| 35 | `release-automation` | 80, 13, 82 | Automate versioning, changelog, tagging, signing and artifact publishing. | `release.sh` bumps SemVer, tags, builds and signs artifacts, and attaches them to the Gitea release |
| 36 | `release-readiness-review` | 80, 38, 1 | Check that tests, security, docs and approvals are complete before shipping, and define rollback. | `readiness_check.py` aggregates gate status, open blockers and test results into a go/no-go checklist |
| 37 | `configuration-baseline-and-drift` | 82, 13, 10 | Capture configuration baselines and detect drift between environments and versions. | `baseline_snapshot.sh` records config and versions; `drift_diff.py` compares a snapshot against live state |
| 38 | `deployment-strategy` | 13, 80, 14 | Run rolling, blue-green and canary deployments with automatic rollback on SLO breach. | `deploy.sh` performs the chosen rollout, watches health checks, and rolls back on failure |
| 39 | `observability-instrumentation` | 14, 17, 41 | Instrument services with logs, metrics and traces (`tracing`, OpenTelemetry) and build dashboards. | `otel_check.sh` verifies that spans, metrics and log fields are emitted and exported |
| 40 | `slo-sli-management` | 14, 4, 5 | Define SLIs and SLOs, error budgets and alerting policy. | `slo_calc.py` computes SLI values and error-budget burn from metrics |
| 41 | `capacity-forecasting` | 14, 41, 73 | Forecast resource needs and cost from load and growth data. | `capacity_forecast.py` fits growth models to usage data and projects capacity and cost |
| 42 | `incident-response` | 81, 14, 66 | Coordinate detection, triage, mitigation, communication and recovery during production incidents. | `incident_open.py` creates the incident issue, a timeline log and communication templates, and pages the on-call agents |
| 43 | `postmortem-authoring` | 81, 14, 2 | Run a blameless review with timeline, causes and tracked action items. | `postmortem_gen.py` builds the draft from the incident timeline and opens action-item issues |
| 44 | `system-hardening` | 31, 10, 9 | Harden operating systems and network services against known attack classes. | `hardening_scan.sh` checks OS and service settings against a CIS-style baseline and lists deviations |
| 45 | `rust-code-implementation` | 15, 16, 17, 18, 20 | Implement features in idiomatic Rust: ownership, error handling with `Result`, traits, modules, tests and docs. | `cargo_check.sh` runs fmt, clippy, build and test and returns a structured pass or fail summary |
| 46 | `async-service-development` | 17, 18 | Build async services with tokio, axum or tonic, including configuration, graceful shutdown and health endpoints. | `scaffold_service.sh` generates a service skeleton with config, tracing and health routes |
| 47 | `database-access-and-migrations` | 17, 29, 18 | Write typed database access (sqlx or diesel) and reversible schema migrations. | `migrate.sh` applies, verifies and rolls back migrations against a throwaway database |
| 48 | `authn-authz-implementation` | 17, 31, 18, 32 | Implement authentication and authorization (OIDC, JWT, RBAC) and test the permission matrix. | `auth_scaffold.sh` adds middleware templates and generates negative authorization tests |
| 49 | `web-frontend-wasm` | 16, 18 | Build web UIs in Rust (leptos or yew) compiled to WebAssembly with state management and API integration. | `wasm_build.sh` builds with trunk, checks bundle size, and runs headless browser smoke tests |
| 50 | `desktop-app-packaging` | 20, 16 | Build and package native desktop apps (egui, iced, tauri) with OS integration and installers. | `package_desktop.sh` produces deb, AppImage, MSI or dmg packages and verifies they launch |
| 51 | `mobile-rust-core` | 19 | Share a Rust core with iOS and Android via uniffi or Tauri mobile and wrap it in native UI. | `gen_bindings.sh` generates Swift and Kotlin bindings and checks that the shared API compiles for both targets |
| 52 | `embedded-no-std-development` | 21, 56, 57 | Write `no_std` firmware (embassy, RTIC) with HAL crates, memory budgets and real-time constraints. | `flash_and_test.sh` builds for the target, flashes with probe-rs, and collects defmt logs |
| 53 | `hardware-in-the-loop-testing` | 21, 39, 56 | Automate tests that run on real or emulated hardware. | `hil_run.sh` runs the test suite on the board or an emulator and returns a JUnit report |
| 54 | `ml-pipeline-engineering` | 22, 25 | Build training, evaluation and inference pipelines in Rust (burn, candle, ONNX runtime). | `train_eval.sh` runs the pipeline with a fixed seed, records metrics and artifacts, and fails on a metric regression |
| 55 | `model-evaluation` | 22, 24, 26 | Design evaluation methodology, metrics, baselines and error analysis. | `eval_report.py` computes metrics and confusion or error slices and renders a markdown report |
| 56 | `ai-feature-integration` | 23, 22 | Integrate LLM and inference features with prompts, tool calls, guardrails and evaluation sets. | `prompt_eval.py` runs a prompt set against the model and scores outputs against expected results |
| 57 | `agent-tool-orchestration` | 23, 71, 2 | Define agent tools, MCP servers and orchestration flows with permissions and limits. | `mcp_tool_scaffold.sh` generates an MCP tool stub with schema and a test harness |
| 58 | `ml-research-experimentation` | 24, 26 | Plan experiments, track runs and compare results with scientific rigor. | `exp_track.py` logs parameters, seeds and metrics per run and compares runs |
| 59 | `etl-pipeline-engineering` | 25, 29 | Build batch and streaming pipelines for extraction, transformation and loading with idempotency and retries. | `pipeline_run.sh` runs a pipeline stage with checkpoints and a row-count and checksum report |
| 60 | `data-quality-management` | 25, 28, 29 | Define and enforce data-quality rules: completeness, uniqueness, validity and freshness. | `dq_check.py` evaluates rule sets against tables and outputs violations |
| 61 | `database-performance-and-schema` | 29, 17 | Design schemas, indexes and queries and fix performance problems. | `explain_analyze.sh` runs EXPLAIN ANALYZE on given queries and flags full scans and missing indexes |
| 62 | `backup-and-restore` | 29, 14, 10 | Define backup policy and prove that restore works. | `restore_test.sh` restores the latest backup into a scratch instance and runs integrity checks |
| 63 | `data-migration-reconciliation` | 29, 25, 17 | Migrate data between systems and prove that the target matches the source. | `reconcile.py` compares counts, checksums and sampled rows between source and target |
| 64 | `statistical-analysis` | 26, 27, 4 | Run hypothesis tests, A/B analysis and predictive models with clear assumptions and uncertainty. | `ab_test.py` computes effect size, confidence intervals and significance for an experiment dataset |
| 65 | `exploratory-analytics` | 27, 30 | Explore data and report product and business metrics. | `eda.py` profiles a dataset and produces summary tables and charts |
| 66 | `metric-modeling` | 28, 30, 27 | Define canonical metrics and transformation models with tests and documentation. | `metric_lint.py` checks metric definitions for ambiguity and duplicates and verifies their SQL or Polars logic |
| 67 | `bi-dashboard-building` | 30, 28, 74 | Build dashboards and executive reports with consistent definitions. | `dashboard_build.py` generates a dashboard spec from metric definitions and validates its queries |
| 68 | `code-review` | 37, 32, 7 | Review PRs for correctness, architecture adherence, idiomatic Rust, maintainability and security. | `review_pr.py` fetches the diff, runs the checklist and clippy results, and posts inline comments with a verdict |
| 69 | `technical-debt-detection` | 37, 7 | Find duplication, complexity, dead code, TODOs and layering violations and rank them. | `debt_scan.sh` combines clippy, complexity metrics, duplicate detection and TODO scans into a ranked report |
| 70 | `test-strategy-planning` | 38, 39 | Plan test levels, coverage targets, environments and quality gates from requirements and risk. | `test_plan.py` generates a test matrix from requirement IDs and risk ratings |
| 71 | `test-harness-and-fixtures` | 39, 40, 21 | Build reusable harnesses, mocks, fakes, simulators and fixtures. | `scaffold_harness.sh` generates a harness crate with fixture builders and mock traits |
| 72 | `test-execution` | 38, 39, 40, 15 | Run unit, integration and end-to-end suites and report results. | `run_tests.sh` runs `cargo nextest`, outputs JUnit, and attaches failures to the issue |
| 73 | `coverage-analysis` | 38, 39 | Measure coverage and identify untested critical paths. | `coverage.sh` runs `cargo llvm-cov`, compares to the threshold, and lists uncovered functions |
| 74 | `property-and-fuzz-testing` | 39, 32, 49 | Test invariants with `proptest` and find crashes with `cargo-fuzz`. | `fuzz_run.sh` runs a time-boxed fuzz campaign, minimizes crashes, and files them as issues |
| 75 | `characterization-testing` | 39, 40, 38 | Record the legacy system's real behavior as golden tests before changing it. | `capture_golden.py` replays inputs against the legacy system and stores outputs as golden files |
| 76 | `parity-and-shadow-diff` | 38, 40, 39 | Compare legacy and new systems on the same inputs and classify differences. | `shadow_diff.py` replays or mirrors traffic to both systems and diffs normalized responses |
| 77 | `bug-reproduction` | 40, 66, 67 | Turn a report into a minimal, reliable reproduction with logs and environment details. | `repro_bug.py` builds a repro script from ticket data and captures logs and versions |
| 78 | `defect-triage` | 38, 40, 2 | Classify, deduplicate, prioritize and route defects. | `bug_triage.py` sets severity and component labels, finds duplicates, and assigns an owner |
| 79 | `performance-benchmarking` | 41, 15 | Benchmark, profile and compare performance with statistically sound methods. | `bench.sh` runs criterion benchmarks, compares to a baseline, and generates a flamegraph |
| 80 | `load-and-scalability-testing` | 41, 14, 11 | Test behavior under load and at scale and find bottlenecks. | `loadtest.sh` runs a load tool (oha, k6 or goose) with a profile and reports latency percentiles and errors |
| 81 | `memory-and-concurrency-verification` | 41, 57, 15, 37 | Verify memory safety and concurrency behavior (`miri`, `loom`, sanitizers, cache analysis). | `miri_loom.sh` runs miri, loom and sanitizer builds and summarizes findings |
| 82 | `threat-modeling` | 31, 35, 32, 6 | Identify assets, trust boundaries, threats and mitigations (STRIDE, attack trees). | `stride_gen.py` generates a STRIDE table per component from the architecture model and opens mitigation issues |
| 83 | `supply-chain-audit` | 32, 31, 77 | Audit dependencies for vulnerabilities, licenses and provenance. | `deps_audit.sh` runs `cargo audit`, `cargo deny` and SBOM generation and outputs advisories and license violations |
| 84 | `unsafe-code-audit` | 32, 37 | Review each `unsafe` block for soundness and justification. | `unsafe_report.sh` runs `cargo geiger`, lists unsafe usage per crate, and checks safety comments |
| 85 | `secrets-and-iam-management` | 33, 31, 13 | Manage secrets, access policies, and least privilege in cloud and CI. | `secret_scan.sh` scans the repo and history for secrets and lints IAM policies for over-broad permissions |
| 86 | `security-monitoring-and-detection` | 34, 36 | Monitor logs and signals, detect threats and investigate anomalies. | `log_hunt.py` runs detection queries over logs and outputs ranked suspicious events |
| 87 | `security-incident-response` | 36, 34, 81 | Run security incident playbooks: containment, evidence, eradication and recovery. | `ir_playbook.py` executes a playbook's steps, records evidence, and updates the incident timeline |
| 88 | `vulnerability-analysis-and-pen-testing` | 34, 31 | Find and validate vulnerabilities in services and infrastructure within agreed scope. | `vuln_scan.sh` runs scoped scanners and outputs findings with severity and reproduction notes |
| 89 | `security-architecture-review` | 35, 31, 6 | Review trust boundaries, identity architecture and defense in depth. | `trust_boundary_check.py` checks the architecture model for flows that cross boundaries without a control |
| 90 | `ux-flow-and-wireframing` | 42, 44, 45 | Design user flows, information architecture and low-fidelity wireframes. | `wireframe.sh` generates low-fidelity SVG or HTML wireframes from a flow description |
| 91 | `design-system-management` | 43, 44, 16, 20 | Maintain visual language, components, typography and design tokens. | `tokens_export.py` converts design tokens into CSS variables and Rust constants |
| 92 | `usability-research` | 45, 46, 42 | Plan and analyze interviews and usability studies and create personas and journeys. | `survey_analyze.py` summarizes responses and task metrics (success rate, time on task, errors) |
| 93 | `cognitive-heuristic-review` | 46, 42, 44 | Review designs for cognitive load, human factors and usability heuristics. | `heuristic_checklist.py` applies a heuristic checklist to a design spec and lists violations |
| 94 | `legacy-ux-audit` | 45, 46, 42, 3 | Map current journeys, pain points and task friction before a redesign. | `journey_map.py` builds a journey map from interview notes and usage logs |
| 95 | `technical-documentation` | 47, 48, 15 | Write and maintain architecture docs, guides and tutorials with rustdoc and mdBook. | `build_docs.sh` runs `cargo doc` and mdBook and checks links and code samples |
| 96 | `api-reference-generation` | 47, 48, 17 | Generate and verify API references that match the code. | `gen_api_docs.sh` builds OpenAPI and rustdoc references and fails on undocumented public items |
| 97 | `release-notes-and-changelog` | 48, 80, 47 | Write user-facing release notes and keep the changelog accurate. | `changelog.py` drafts notes from merged PRs and issue labels using conventional commits |
| 98 | `knowledge-base-sync` | 47, 71, 2 | Keep the wiki, ADRs and docs aligned with merged work. | `wiki_sync.py` updates wiki pages from merged PRs and flags stale pages |
| 99 | `mathematical-modeling-and-proofs` | 49, 24 | Build formal models and check derivations, proofs and complexity. | `symbolic_check.py` verifies derivations and identities symbolically with sympy |
| 100 | `numerical-convergence-analysis` | 49, 50, 24 | Choose methods and demonstrate order of convergence, stability and error bounds. | `convergence_study.py` runs refinement series and fits the observed convergence order |
| 101 | `physics-model-specification` | 50, 3, 49 | Write the governing equations, assumptions, units, boundary conditions and validity range of a model. | `model_spec_lint.py` checks that the spec defines all symbols, units and boundary conditions |
| 102 | `units-and-dimension-checking` | 50, 15, 54 | Prevent unit and dimension errors with typed units in code and checks on specs. | `dimension_check.py` checks equations for dimensional consistency and flags raw floats in public APIs |
| 103 | `simulation-validation` | 50, 54, 55, 56, 51, 52 | Compare simulation results against analytic cases, benchmarks or experimental data with defined metrics and tolerances. | `compare_results.py` computes L2, Linf and conservation errors against reference data and renders a validation report |
| 104 | `mechanical-and-structural-analysis` | 54, 55 | Check stress, loads, mechanisms, materials and structural models. | `fem_check.py` runs reference static or modal cases and compares them with the model output |
| 105 | `circuit-and-signal-analysis` | 56, 21, 57 | Analyze circuits, sensors and signal chains and define hardware and software interfaces. | `spice_run.sh` runs circuit simulations and extracts voltages, timing and spectra |
| 106 | `hardware-architecture-analysis` | 57, 41, 21 | Analyze CPU, memory hierarchy, buses and peripherals to guide data layout and optimization. | `hw_probe.sh` reports CPU features, cache sizes, NUMA topology and memory bandwidth |
| 107 | `chemistry-model-validation` | 51, 50 | Validate chemical models, kinetics and material properties. | `kinetics_check.py` checks rate laws, mass balance and thermodynamic consistency |
| 108 | `biological-model-validation` | 52, 24 | Validate biological models and interpret biological data. | `bio_check.py` runs model outputs against reference datasets and checks plausibility ranges |
| 109 | `clinical-safety-checking` | 53, 78, 31 | Check medical terminology, safety thresholds and compliance with clinical guidelines. | `threshold_check.py` compares configured limits and outputs with guideline values and flags violations |
| 110 | `ethics-and-assumption-analysis` | 58, 1, 35 | Examine assumptions, value conflicts and consistency of arguments behind decisions. | `assumption_log.py` extracts assumptions from design docs and ADRs and tracks which are validated |
| 111 | `product-positioning-and-messaging` | 59, 4, 61 | Define positioning, segments, messaging and competitive framing. | `positioning_canvas.py` fills a positioning template from product docs and competitor notes |
| 112 | `growth-experimentation` | 60, 27, 26 | Design and measure acquisition, activation and retention experiments. | `growth_funnel.py` computes funnel conversion by cohort and tracks experiments |
| 113 | `technical-content-and-seo` | 61, 48 | Plan technical content and SEO and measure search visibility. | `seo_audit.py` checks pages for titles, metadata and keywords and reports gaps |
| 114 | `sales-demo-and-poc` | 62, 15, 68 | Prepare demos, proof-of-concepts and architecture proposals tied to customer needs. | `demo_env.sh` provisions a disposable demo environment with sample data and resets it after use |
| 115 | `partnership-evaluation` | 63, 77, 4 | Assess partnership and market opportunities, fit and risk. | `partner_score.py` scores opportunities against criteria and outputs an assessment table |
| 116 | `account-health-management` | 64, 65 | Track account health, renewals and expansion opportunities. | `account_health.py` computes a health score from usage, tickets and sentiment |
| 117 | `customer-onboarding` | 65, 68, 48 | Guide customers to adoption with checklists, configuration and training. | `onboarding_check.py` tracks onboarding milestones per customer and flags stalled steps |
| 118 | `support-ticket-triage` | 66, 67, 69 | Classify and route support tickets, and escalate to engineering with full context. | `ticket_triage.py` classifies a ticket, links related issues, and sets priority and queue |
| 119 | `support-intake-and-faq` | 67, 66 | Handle first-line support, maintain FAQs, and communicate status to customers. | `faq_search.py` finds matching FAQ entries and drafts a reply for review |
| 120 | `customer-implementation` | 68, 65 | Configure, deploy and integrate the product for a specific customer. | `customer_config.sh` renders and validates customer-specific configuration and runs an integration smoke test |
| 121 | `workstation-provisioning` | 69, 70, 10 | Set up developer and staff machines with the toolchain and correct access. | `provision_ws.sh` installs the Rust toolchain, tools and configuration and verifies versions |
| 122 | `access-and-asset-management` | 70, 69 | Manage user access, hardware and software assets, and IT policy compliance. | `access_review.py` lists users, groups and assets and flags stale or excessive access |
| 123 | `internal-tooling` | 71, 13, 12 | Build and maintain internal tools, automation and productivity infrastructure. | `tool_scaffold.sh` generates a Rust CLI or service template wired into CI and the docs |
| 124 | `accounting-reconciliation` | 72, 73 | Reconcile transactions, maintain records and produce financial reports. | `reconcile_ledger.py` matches ledger entries to statements and lists unmatched items |
| 125 | `financial-modeling` | 73, 74, 5 | Build budgets, forecasts and cost analyses for decisions. | `fin_model.py` computes scenarios from assumptions and outputs a forecast table |
| 126 | `budget-governance` | 74, 5, 1 | Set financial controls, approvals and investment decisions. | `budget_check.py` compares actual spend to budget by project and flags overruns |
| 127 | `hiring-pipeline` | 75, 76, 2 | Define role needs, sourcing, interview kits and hiring workflow. | `interview_kit.py` generates a rubric and question set from the role requirements |
| 128 | `organizational-policy-and-performance` | 75, 79 | Maintain employee policies and performance processes and align operations. | `policy_index.py` tracks policy versions and review dates and flags overdue reviews |
| 129 | `license-and-ip-review` | 77, 32 | Review software licenses, intellectual property and legal risk. | `license_check.py` classifies dependency licenses against the allowed policy and generates a notice file |
| 130 | `contract-and-terms-review` | 77, 63, 64 | Review contracts, terms and obligations that affect product or delivery. | `clause_extract.py` extracts key clauses (term, liability, IP, SLA) into a summary table |
| 131 | `compliance-evidence-collection` | 78, 77, 31, 47 | Map controls to requirements and collect audit evidence. | `evidence_collect.sh` gathers CI logs, approvals and scan reports per control into an evidence folder |



### Building .kilo harness set

I prompted the following text in the claude.ai web interface that it gave me kilo code commands, agents and skills that are loaded on demand.

1. can you create a .kilo/commands, and .kilo/agents and .kilo/skills and .kilo/skills/scripts all for these commands, agents, skills listed above as a zip file?
2. as i only have 32kb context size, i need to implement commands, agents, skills that will be enabled / disabled dynamically (loaded/unloaded from context) by using different levels of agentic memories
3. also can you make use of rtk, caveman , graphify , ponytail in your md files and scripts, and reprepare the zip file?
4. i need the developer and other roles to pay attention to these topic also , can you add these to the md files  of kilo dynamic pack, as topics to pay attention before starting to work   :  0. every code should be written in domain driven architecture, clean code and test driven approach. 1.  for the coordinator : read $RUST_DEV_ENV/books/rust_design_patterns.pdf and summarize it part by part  and output to summaries/rust_design_patterns.pdf.md file if this file does not exists. And for the developer and reviewer roles , they should obey the patterns summarized in it. 2.  developers and reviewers should pay attention to $SDK_DEV_ENV/reference-projects/COMMON_MISTAKES.md and reference-projects/PRINCIPLES.md 3. Pay attention to karpathy rules , download and put the files in .kilo directory the file https://github.com/multica-ai/andrej-karpathy-skills/blob/main/skills/karpathy-guidelines/SKILL.md as karpathy_skill.md .
5. I added two bullets manually in coordinator.md :
   - Analyze the assigned issue or document link assigned using a gitea issue, checks consistency, ambiguity, contradiction, Completeness, Redundancy, Validity, Relevance, Accuracy, Clarity, Correctness, Entailment, Satisfiability.          
   - In each step, every agent sends it's task to researcher to check if there already is an open source program / library. This agent makes research on the internet using google.com, scholar.google.com, or any ai site if it can.
6. Go to $RUST_AGENT_INFRA_DIR/harness/kilo_commands_agents_skills/dot.kilo/library/agents, create a gitea user for all agents in 

### Installing and Using .kilo harness set

Go to your project directory and run the script $RUST_AGENT_INFRA_DIR/harness/install_kilo_harness.sh. This will install predefined skilss/modes/workflows from $RUST_AGENT_INFRA_DIR/harness/ directory. The directory content is prepared using the following sites :




