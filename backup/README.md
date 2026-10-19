# agent-infra

Agent-infra repository contains scripts, descriptions and example use cases of a local/offline/air-gapped agentic development environment.

In this repository we describe: 
1. Architecture Design Records about tool/service choices among other alternatives.
2. Simple usage example of each tool/service individually.
3. Usage of these tools/services in a full cycle development scenario.

ATTENTION: 
1. After cloning this repository, source the release file found in the repository before running any script .
2. "Start scripts" in services directory only triggers the existing container if it exists. If you change anything in the script, you should remove the container. ( E.g :  sudo docker rm -f VLLM_0; cd services;./01.vllm.sh)


| Component | Type | Description |
| --------- | ---- | ----------- | 
| VLLM | SERVICE | LLM Inference Engine | 
| New API | SERVICE | LLM Proxy ( AI model gateway) | 
| N8N | SERVICE | n8n is a web based workflow automation platform that uniquely combines AI capabilities with business process automation | 
| NE04J | SERVICE | Neo4j is a native graph DB | 
| Apache Jena Fuseki | SERVICE | To Serve Ontology Files| 
| Qdrant | SERVICE | Vector DB| 
| GraphRAG (Tigergraph) | SERVICE | GraphRAG (Graph Retrieval-Augmented Generation) enhances traditional RAG by embedding knowledge graphs into the LLM inference process. |
| Protege | TOOL | Ontology Development Tool | 
| Okf Harness| TOOL | an independent, open-source, terminal-native tool designed to help AI coding agents maintain local knowledge bases using Google’s Open Knowledge Format (OKF) | 
| Obsidian | TOOL | Obsidian is a popular note-taking and knowledge-management application that stores files as plain text Markdown documents on your local device| 
| Open Wiki | TOOL | OpenWiki is an open-source command-line interface (CLI) tool built by LangChain designed to write and automatically maintain structured Markdown documentation for codebases using LLM agents. |
| Deep Seek Harness | TOOL | an open-source, MIT-licensed agent runtime and framework developed by DeepSeek AI that wraps a large language model (LLM) with the tools, memory, sandboxes, and loop control needed to operate as an autonomous coding and task agent| 
| Kilo-Code CLI | TOOL | An open source agentic command-line coding tool  | 
| Graphify | TOOL | an open-source tool and AI coding-assistant skill that turns a project's files—including code, documentation, PDFs, images, and videos—into a queryable knowledge graph | 
| Caveman | TOOL | Installed within Coding Agents. This tool reduces tokens before sanding to inference service |
| RTK | TOOL | Rust Token Killer is a command-line proxy sitting between your AI agent and the shell that intercepts verbose outputs (like git log) and returns clean, deduplicated, and condensed text |
| Ponytail | TOOL | It pushes the agent to reuse existing code, platform features, and dependencies before writing anything new. |



## Hardware and OS Requirements to Run This Environment:
	
1.  A computer with a NVIDIA GPU that is supported by VLLM 

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

## Principles

1. Don’t spam prompts to fix errors (Prompt Thrashing).
2. Don’t assume model is understanding ( Write Clear Prompts)
3. Don’t use too many MCP Servers (Risk of selecting wrong MCP would increase)
4. Regularly reevaluate (possibly outdated) assumptions about the"best" tools
5. Don’t persist with dead-end conversations
5. Chain of Tought (COT) : Explain step by step what to do.
6. Input Data (Previous mails, examples) IN PARANTHESIS
7. Explicit Negative : If you want to emphasize womething not to do, especially explain it so.
8. Venn Diagram of what is possible : Intersection, Union, Exclusion

##  Usage

After starting the services, we are ready to use agentic tools. 

### 1. Simple Rust Development With One Agent
#### 1.1. Prepare Work Directory and Github Repository
	mkdir -p ~/agentspace
	cd ~/agentspace
	git clone git@github.com:mehmetpekmezci/agent-managed-rust-project.git
	
#### 1.2. Code Generation
We prepared rust development environment using https://github.com/havelsan/rust-dev-env in directory ~/sdk/rust-dev-env. We will use the compiler and cargo from this directory.
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
			
#### 1.3. Code Review
	source ~sdk/rust-dev-env/release
	source ~/workspace/agent-infra/release
	cd ~/agentspace/agent-managed-rust-project
	kilo
		> your role is "code reviewer". review the code in the simple_calculator directory and evaluate the codes by using the coding principles in ~/sdk/rust-dev-env/reference-projects/PRINCIPLES.md and ~/sdk/rust-dev-env/reference-projects/COMMON_MISTAKES.md. Run cargo clippy --all-targets --all-features to verify warnings. Note the issues into the ~/agentspace/agent-managed-rust-project/simple_calculator/issues/REVIEW-001.md  file.
			> The LLM generates comments in ~/agentspace/agent-managed-rust-project/simple_calculator/issues/REVIEW-001.md (262 lines)

#### 1.4. Code Improvement
	source ~sdk/rust-dev-env/release
	source ~/workspace/agent-infra/release
	cd ~/agentspace/agent-managed-rust-project
	kilo
		> Make a step by step plan for to improve the code in simple_calculator project using the code review notes in ~/agentspace/agent-managed-rust-project/simple_calculator/issues/REVIEW-001.md and write the into ~/agentspace/agent-managed-rust-project/simple_calculator/plans/PLAN-01.md.  Steps of the plan should be as small as possible so that we can fit into 32k context :) 
			> The LLM Says : Plan generated.
		> Execute each step one by one. Write the executed steps of the plan into ~/agentspace/agent-managed-rust-project/simple_calculator/plans/PLAN-REPORT-01.md
			> The LLM Says : Compaction exhausted: context still exceeds model limits after 3 attempts



#### 1.5. Code Improvement Using Token Reduction Tools
Now we configure token reduction tools, you may check the descriptions of each tool that is used below from the [ Token Reduction ADR ](docs/ards/adr-005-context-token-reduction-tools.md)
As we do the configuretion, from now on when you run the installation scripts, it will be automatically configured, for example headroom service is automatically configured and kilo.jsonc is configured fot headroom. 
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
        
### 2 Building Harness
Agent = Model + Harness. The harness does six things the model cannot do on its own. 
1. It shapes what the model sees on each call (context assembly). 
2. It decides what the model is allowed to do (tool contracts and validators). 
3. It remembers what happened across calls (memory and durable state). 
4. It watches what the model produced (observability, verification, drift detection, evaluation gates). 
5. It recovers when something goes wrong (retry, rollback, checkpointing, replay).
6. It coordinates multiple agents (orchestration, subagents, human-in-the-loop, agent-to-agent protocols). (Rick Hightower)



Framework vs Harness:
A framework gives you abstractions, libraries, and components for building agent systems. The harness is the operational system surrounding the model. It determines which actions are available, what actually executes, how results are checked, and what happens after failure. In doing so, the harness governs system execution across context, tools, state, orchestration, verification, observability, and control. In contrast, a framework can be used to implement parts of a harness. You can combine multiple frameworks within a harness or choose not to use a dedicated agent framework at all. Consequently, the distinction between agent frameworks and agent harnesses lies in implementation tooling versus system responsibility and control.


Harness design has matured from ad-hoc scripting into a systems-engineering discipline with its own lifecycle, security model, and token economics. That system is your harness: the engineered layer around your AI agents that constructs context, governs tool interaction, manages state, orchestrates execution, interprets feedback, verifies outcomes, and enforces constraints. The model supplies general-purpose intelligence during inference, but the harness turns that inference into situated, persistent, controlled intelligence and interpretable behavior. Increasingly, the harness itself becomes a learnable system layer that can be adjusted and optimized while the underlying model remains fixed.



 Figure 1-1 shows the main harness layers that you author, own, and improve, and how they work together as a closed operational loop.
 
 Figure 1-1 separates the harness into six layers that play different roles in your operational loop. The following briefly explains what each layer is about and why it is important for your agent system.

 Figure 1-2 places prompt engineering and context engineering side by side with this broader stage of harness engineering. 
 You’ll notice that the model is fixed in all three columns. What changes is how much of the system around the model you are willing to treat as something you deliberately engineer.
 



If you look closely at the figure, you’ll notice that the diagram closes. The harness is not a stack of disconnected components, but a closed operational and improvement loop. Your runtime behavior becomes observable, observability supports verification, verification provides the signal for adaptation, and adaptation changes how the system behaves the next time it runs.





    
    
    
    
    
The Harness Is More Than a Wrapper

If you look at an AI agent system, it’s easy to think that the code around the model is just a temporary wrapper. But as the incident example shows, the model is only the reasoning engine. The harness is where your business logic, policies, and operational reality live. A model doesn’t know your company’s rollback permissions, nor should you rely on it to enforce them reliably. The harness is the system of record for how work actually gets done in your application.




1    The tool set defines which read-only actions the harness can expose during execution.
2    The recorder gives later components access to observations and traces produced as execution progresses.
3    The tool gateway connects governance, tool access, execution, and observability rather than letting the model invoke the environment directly.
4    Verification receives the recorder because it needs evidence produced elsewhere in the harness to evaluate the result.
5    Orchestration brings the components together and uses their outputs to control what happens next.    
    
However, making your agents stateful doesn’t mean that state exists in only one place or for one lifetime inside your harness. Some state exists only for the current model decision, some tracks the progress of your workflow, some reflects what is happening in the external environment, and some must survive beyond the active execution altogether. The following gives you an overview of how you can separate the state your harness manages into four categories.

Model context

    The information currently visible to the model.
Workflow state

    The current task position, completed steps, pending actions, retry counts, and intermediate results.
Operational state

    The state of the external environment, including files, services, deployments, approvals, and tool outputs.
Durable state

    Information persisted outside the active run so that the system can resume, inspect, reuse, or audit it later.

The four state categories describe different lifetimes, but they also clarify an important boundary between the model and the harness. The model can only decide over the state that enters its current context. It doesn’t inherently know where the task is in a longer workflow, which effects have already happened, which approvals are pending, or which artifacts another agent produced unless the harness makes that information available.

    
    
    
    
    
    
    
    
    
    
    
    
    


https://github.com/wquguru/harness-books


Search Harness Engineering
search Jarosław Wąsowski

https://medium.com/@asimsultan2/agent-harness-engineering-the-new-layer-of-ai-that-everyone-will-be-talking-about-a500dd80c2dd

https://medium.com/@johnklaumann/harness-engineering-agent-llm-router-and-ai-coding-ffacb012ecbe



How I Structure Claude Code Projects So Agents Don’t Get Lost in Large Codebases (https://blog.s10n.dev/how-i-structure-claude-code-projects-so-agents-dont-get-lost-in-large-codebases-9ad69a2ebb92)
How To Use Claude Like a Senior Engineer, Not a Chatbot (https://medium.com/codetodeploy/how-to-use-claude-like-a-senior-engineer-not-a-chatbot-6490dcaf1614)


How to create a skill worth using  (https://uxplanet.org/i-tested-20-popular-claude-code-skills-most-of-them-were-useless-6bfdf190a6d1)

If you’re building your own skill, follow this path:

    Start from a real, recurring pain, not a topic. For example, “Our checkout form keeps shipping without the analytics events wired up” is a pain worth a skill.
    Provide workflow, not individual actions. You need to guide AI on how to solve the problem. This guidance should be explain the process you follow when dealing with the problem.
    Encode the decision, not the principle. Skip “handle errors gracefully.” Write “in this service, wrap external calls in withRetry and surface failures through AppError, never raw exceptions."
    Cut anything the model does by default. If Claude already does it without being told, deleting it costs you nothing.
    Keep the main instructions short; push depth into referenced files. Use progressive disclosure and let Claude load the detail only when the task demands it.
    Measure. Run the task with and without the skill. If the output doesn’t change, or doesn’t change for the better, the skill isn’t earning its context.


Multiagent example : bussiness analyst, architect, coder, document generator, unit test coder, scenario test coder, code reviewer( bitbucket) , static analyzer(mcp), test runner, test report generator, release manager, product admin, platform admin.
Skills and coding book rags

https://github.com/garrytan/gstack
https://github.com/Kilo-Org/kilo-marketplace
https://github.com/addyosmani/agent-skills
https://github.com/obra/superpowers


Coding Skills/Harnesses

    Karpathy (https://github.com/multica-ai/andrej-karpathy-skills)
    
    Rust (https://github.com/leonardomso/rust-skills)
    
    Qt (https://github.com/theqtcompanyrnd/agent-skills, https://www.qt.io/blog/introducing-qt-agentic-development-skills)
    
    Voltagent Agent Skills (https://github.com/VoltAgent/awesome-agent-skills)
    
    Dev Skills (https://github.com/jamestorrevillas/dev-skills)
    
    Skillizer (https://github.com/skullzarmy/skillerizer)
    
    Anthropics (https://github.com/anthropics/skills/)
    
    Design Skills (https://github.com/bergside/awesome-design-skills)
    
    Hexagonal Skills (https://github.com/affaan-m/ECC/blob/main/skills/hexagonal-architecture/SKILL.md)
    
    Java Coding Standards Skills (https://github.com/vibeeval/vibecosystem/blob/main/skills/java-coding-standards/SKILL.md)
    https://lazyskills.sh/skills/java
    https://github.com/pepperize/java-skills
    https://github.com/agentscope-ai/agentscope-java
    https://github.com/brunoborges/jdb-agentic-debugger
    https://github.com/soujava/agent-skills
    https://github.com/jdubois/dr-jskill
    
    Awesome Claude Skills (https://awesomeclaude.ai/awesome-claude-skills)
    
    Harnesses (https://medium.com/intuitively-and-exhaustively-explained/towards-self-repairing-and-repeatable-ai-systems-9371046804e5)

    Harness Repo-1 (https://github.com/Ancienttwo/repo-harness)

    Harness for Devops (https://github.com/harness/harness)

    Harness Links Repo (https://github.com/walkinglabs/awesome-harness-engineering)

    Harness Long-Horizon (https://github.com/AMAP-ML/LongHorizon-Harness)

    Harness Team-Arch Factory (https://github.com/revfactory/harness)

    Harness Skills (https://github.com/harness/harness-skills)

    Harness Developer Hub (https://developer.harness.io/docs/internal-developer-portal/flows/workflows-tutorials/github-repo-onb/)

    Harness Engineering (https://skywork.ai/skypage/en/ultimate-guide-harness-engineering-tools/2054107263857094657)

    NASA's 10 rules
    
    Elon Musk's Advice

MCP Servers
 
    Atlassian (https://github.com/mshashank0/mcp-server-for-atlassian-ai-assistant)
    
    All MCP Servers (https://mcpservers.org/)

