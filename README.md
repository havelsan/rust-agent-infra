# rust-agent-infra

rust-agent-infra repository contains scripts, descriptions and example use cases of a local/offline/air-gapped agentic development environment.

In this repository we describe: 
 
1. Architecture Design Records about tool/service choices among other alternatives.
2. How to trigger installation and services scripts.
3. Simple usage example of each tools/services individually.
4. Usage of these tools/services in a full cycle development scenario.


**CAUTION:**
1. "Kilo Code" either CLI or VSCode extension, should be run in a non-privileged account of operating system. In ubuntu 24.04, perform the installations which are described below,  and start the services using an account with a SUDO privileged account. After starting the services, you should switch to an account with no SUDO privilege while running "Kilo Code" executable or vs code extension.
 
2. If "Kilo Code" is using a system like issue tracker / DB / any type of server, the user account provided to "kilo code" agents should not have any admin privilege.

**ATTENTION:** 
1. After cloning this repository, source the release file found in the repository before running any script .
2. "Start scripts" in services directory only triggers the existing container if it exists. If you change anything in the script, you should remove the container. ( E.g :  sudo docker rm -f VLLM_0; cd services;./01.vllm.sh)
3. These scripts ( e.g. 04.new_api.sh ) also have descriptions in them like creating account and creating an API_KEY, please read them also.


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
3. How we do context token reduction :  [CONTEXT_TOKEN_REDUCTION](docs/adrs/adr-003-context-token-reduction-tools.md)


##  Installation of Services and Tools 

Clone this repository into your wworkspace directory, source the release file and run the ~/workspace/rust-agent-infra/install/00.main.sh  script.
    
##  Starting Services

After installing services and tools, source the ~/workspace/rust-agent-infra/release file then start services by running the ~/workspace/rust-agent-infra/services/00.main.sh script.

**Very Important Note :  To configure API_KEY please take a look at the end of services/04.new_api.sh file !** 

## Simple Usage Example 

After starting the services, we are ready to use kilo agentic coding tool. 

#### Prepare Work Directory

	mkdir -p ~/agentspace/agent-managed-rust-project
	cd ~/agentspace/agent-managed-rust-project


	
#### Code Generation
We prepared rust development environment using https://github.com/havelsan/rust-dev-env in directory ~/sdk/rust-dev-env and we will use the compiler and cargo from that directory.

	source ~/sdk/rust-dev-env/release
	source ~/workspace/rust-agent-infra/release
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
	source ~/workspace/rust-agent-infra/release
	cd ~/agentspace/agent-managed-rust-project
	kilo
		> your role is "code reviewer". review the code in the simple_calculator directory and evaluate the codes by using the coding principles in ~/sdk/rust-dev-env/reference-projects/PRINCIPLES.md and ~/sdk/rust-dev-env/reference-projects/COMMON_MISTAKES.md. Run cargo clippy --all-targets --all-features to verify warnings. Note the issues into the ~/agentspace/agent-managed-rust-project/simple_calculator/issues/REVIEW-001.md  file.
			> The LLM generates comments in ~/agentspace/agent-managed-rust-project/simple_calculator/issues/REVIEW-001.md (262 lines)


#### Code Improvement

	source ~sdk/rust-dev-env/release
	source ~/workspace/rust-agent-infra/release
	cd ~/agentspace/agent-managed-rust-project
	kilo
		> Make a step by step plan for to improve the code in simple_calculator project using the code review notes in ~/agentspace/agent-managed-rust-project/simple_calculator/issues/REVIEW-001.md and write the into ~/agentspace/agent-managed-rust-project/simple_calculator/plans/PLAN-01.md.  Steps of the plan should be as small as possible so that we can fit into 64k context :) 
			> The LLM Says : Plan generated.
		> Execute each step one by one. Write the executed steps of the plan into ~/agentspace/agent-managed-rust-project/simple_calculator/plans/PLAN-REPORT-01.md
			> The LLM Says : Compaction exhausted: context still exceeds model limits after 3 attempts


As you see from the LLM response, LLM could not make the improvement, so we tried to reduce the number of tokens, which is shown in next section.

#### Code Improvement Using Token Reduction Tools

Now we configure token reduction tools, you may check the descriptions of each tool that is used below from the [ Token Reduction ADR ](docs/ards/adr-005-context-token-reduction-tools.md)


	source ~sdk/rust-dev-env/release
	source ~/workspace/rust-agent-infra/release
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

0. Switch to a user that can NOT execute sudo commands without providing password, and also that does NOT have git master/tag privileges.
1. Clone a copy of your project into a directory.
2. Checkout a branch that "kilo code agent" can commit. (or even push)
3. Source the release file : ~workspace/rust-agent-infra/release 
4. Run the harness installation script : ( ~workspace/rust-agent-infra/harness/install.sh)  

Installation command does the following :

1. create .kilo directory if it does not exists
2. creates skills and agents directory 
3. copies kilo.jsonc file
4. links the $AGENT_INFRA_DIR/harness/skills/* directories
5. link the $AGENT_INFRA_DIR/harness/agents/* files.

NOTE: we could also install in ~/.config/kilo/ directory. But we don't prefer to make a global installation, we install to only in-repository <project_dir>/.kilo directory.

##  How to Write Prompt

How to write a prompt is described in  [HOW_TO_WRITE_PROMPT](docs/howtos/01.prompt.md)

## How to Write Skill

How to write a skill is described in  [HOW_TO_WRITE_SKILL](docs/howtos/02.skill.md)


## How to Write Agents (SubAgents/Modes/Roles)

How to write an agent is described in  [HOW_TO_WRITE_AGENT](docs/howtos/03.agent.md)


## How to Write MCPs 
 
There are already good guides on the web about this topic :

	https://modelcontextprotocol.io/docs/2026-07-28/getting-started/intro
	https://modelcontextprotocol.io/docs/2026-07-28/develop/build-server
	https://modelcontextprotocol.info/docs/tutorials/writing-effective-tools/
	


## Building Harness using Skills + Agents + Memory + MCPs

We build a harness for our development environment.  We will use the following main parts in our development environment, so the harness will be built around them :

1. rust
2. gitea
3. kilo code

### Rust Check List

1. Install [rust-dev-env](https://github.com/havelsan/rust-dev-env) in $HOME/sdk/rust-dev-env  

### Gitea Check List

1. Go to ~/sdk/rust-dev-env directory
    -  source release file
    -  go to rust-dev-env/rust directory and run install.sh
    -  go to rust-dev-env/devops directory and run install.sh , also follow the instructions in README.md file in that directory to create example users , projects and organizations. Also creating PERSONAL ACCESS TOKEN is written in that README.md file.
    
2. Start the gitea if not already started :
    - cd ~/sdk/rust-dev-env/devops/bin; ./run_gitea.sh
    - This starts gitea at URL : "http://localhost:13000"

3. Gitea-mcp binary is also installed while installing gitea, you may also test it 
     - source ~/sdk/rust-dev-env/release
     - gitea-mcp -t stdio --host "http://localhost:13000" --token "7dcf5fa2452b48cbd4c91045996fc6e4e4115428"
           - We assume that the token in this command was generated in the first step by reading the $RUST_DEV_ENV/devops/README.md 
           - After writing this command , we send following json messages and expect any response. If we obtain any response, gitea and mcp are working.
                 - {"jsonrpc":"2.0","id":1,"result":{"capabilities":{"tools":{}},"protocolVersion":"2024-11-05","serverInfo":{"name":"Gitea MCP Server","version":"1.8.0"}}}
                 - {"jsonrpc": "2.0", "method": "tools/list", "id": 1}
 
### Kilo Code Check List

1. Check the .config/kilo/kilo.jsonc file, this should be the same as $RUST_AGENT_INFRA_DIR/install/23.kilo.jsonc  file and should contain mcp part. 

>	  "mcp": {
>	    "gitea": {
>	      "type": "local",
>	      "command": ["gitea-mcp"],
>	      "args": ["-t", "stdio"],
>	      "enabled": true,
>	      "environment": {
>	        "GITEA_HOST": "http://localhost:13000",
>	        "GITEA_ACCESS_TOKEN": "{env:GITEA_USER_PAT}"
>	      }
>	    }
>	  }


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


### Gitea Configs

Before starting to work with agents we create the folowing organization, users and a git repository in gitea :

1. Organization :  rust-agentic-org

   1. Goto http://localhost:13000/ GITEA in browser.
   2. Login as admin (if you follow rus-dev-env , default is adm001/adm001+++ ) 
   3. Click on the "+" icon on the right-top of the page.
   4. Click "new organization"
        1. Organization Name : rust-agentic-org
        2. Visibility : public
        3. Permissions : repository admin can add and remove access for teams
   5. Click on rust-agentic-org and click on settings
   6. Click on "Labels" on left side panel.
   7. Click on New Label
   8. Define the following labels ( agent/ and status/ labels can be mutually exclusive).  important: select "Exclusive"  while creating the label:
   8.1. agent/Human
   8.2. agent/Coordinator
   8.3. agent/Analyzer
   8.4. agent/Architect
   8.5. agent/Designer
   8.6. agent/Developer
   8.7. agent/Qa
   8.8. agent/RequirementsEngineer
   8.9. agent/Reviewer
   8.10. agent/Tester
   8.11. status/todo
   8.12. status/in-progress
   8.13. status/blocked
   8.14. status/done
   

 

2. Create Users (human, agent ( the AI user) ) :  

   1. Goto http://localhost:13000/ GITEA in browser.
   2. Login as admin (if you follow rus-dev-env , default is adm001/adm001+++ ) 
   3. Click on the icon on the right-top of  most the page.
   4. Click "site administration"
   5. Click on the "Identity & Access" menu item on the left menu.
   6. Click on the "User Accounts" menu item
   7. Click on the "Create User Account" button on the right-top of the page.
        1. Authentication Source : local
        2. User visibility : public
        3. User name : agent
        4. Email : agent@localhost.org  
        5. Password : qwe123***
        6. Un check the "Require user to change the password"
        7. click "Create user account"
   8. create personal access tokens
        1. Login as agent
        2. Click on the rigt-top most icon on the page 
        3. Click on the "settings" menu item
        4. Click on the "Applications" menu item
        5. Generate new token
            1. Token Name : GITEA_AGENT_PERSONAL_ACCESS_TOKEN
            2. Repository and Organization Access : All
            3. Token Permissions : (activitypub, issue, misc, notification, organization, package, repository, user)  = (  Read and Write )
            4. Click on the "Create Token" button
            5. copy the token appearing on the top of the page.
            6. insert the "export GITEA_AGENT_PERSONAL_ACCESS_TOKEN=2f9a261f35a9bbd8c2e054165b3d55b4cd1f43ea" line in the $HOME/workspace/rust-agent-infra/release 
   9. In the end the following three lines should inserted in the $HOME/workspace/rust-agent-infra/release file.


> export GITEA_AGENT_PERSONAL_ACCESS_TOKEN=2f9a261f35a9bbd8c2e054165b3d55b4cd1f43ea



3. Create "purchase" Repository :

   1. Login GITEA as admin001 user.
   2. Click on the "Explore" menu item on the top-left menu.
   3. Click on the "Organizations" tab.
   4. Click on the "rust-agentic-org"
   5. Click on the "New Team" button
      1. Tean Name : agentic-team
      2. Description : Agentic Team
      3. Visibility : public
      4. Repository Access : All Repositories
      5. Create Repositories is checked ( Memebers can cretae new repositories within the organization)
      6. Permissin : Administrator Access
      7. Click on the "Create Team" button
      8. Add agent, human users to this team using "Add Team Member" 
   6. Return back to the "rust-agentic-org" page using Explore > Organizations > rust-agentic-org
   7. Create a new repository using "Create New Repository" button
      1. Owner : rust-agentic-org
      2. Repository name : purchase
      3. Visibility: NOT CHECKED: Mahe repository Private. ( The repository is public)
      4. Description : Purchase List Coordinator
      5. Tepmplate :  DID_NOT_SELECT_ANYTHING
      6. Issue Labels : Advanced
      7. .gitignore : Rust
      8. License : 0BSD
      9. Readme : Default
      10. Default Branch: main
      11. Object Format: sha1
      12. Template : NOT_CHECKED: Make repository a template.
      13. Click on the Create Repository
      

We assume that an agentic team composed of Human, Coordinator, RequirementsEngineer, Analyzer, Researcher, Architect, Developer, Designer, Reviewer, Tester, and QA uses the repository's issues and wiki in Gitea to communicate with each other. 

When a Human assigns an issue to the Coordinator, the project starts. The Coordinator may assign an issue back to the Human if it cannot determine what to do.

> **Note:** The Kilo agent (which automatically starts the Coordinator sub-agent) is launched by running the `start_agent.sh` command installed by the `$RUST_AGENT_INFRA_DIR/harness/install.sh` script.



### Agents

We currently assume that a team of agents (agentic-team composed of Human, Coordinator, RequirementsEngineer, Analyzer, Researcher, Architect, Developer, Designer, Reviewer, Tester, Qa) will use "purchase"  git repository's issues and wiki in gitea to communicate each other. When a Human assigns an issue to Coordinator (the agent) the project starts. Coordinator may assign an issue to human if it can not determine what to do. 

| Agent No | Agent Name                             | Description               |
| ------: | ------------------------------------- | ---------------------- |
|   **0** | Human                                 |  Starts the project by assigning an issue to the coordinator. Every critical decision should be asked to this role through the gitea issues.|
|   **1** | Coordinator                           |  Central coordination agent. Owns project-level workflow; communicates with the Human and all agents through Gitea Issues; assigns, tracks, and escalates work. Coordinator assigns the issue to the worker. Also the role to use while resolving the issue is indicated within the issue by coordinator. |
|   **2** | RequirementsEngineer                  |  Requirement Engineer agent analyzes requirements and generates use cases, user stories, test cases. |
|   **3** | Analyzer                              |  Analyze the assigned issue or document link assigned using a gitea issue, checks consistency, ambiguity, contradiction, completeness, redundancy, validity, relevance, accuracy, clarity, correctness, entailment, satisfiability. Build wiki for requirements of a project if the coordinator asks for it. Also check for asd-ste100 using asd-ste10-skill that can be found in $RUST_AGENT_INFRA_DIR/harness/library/skills. Also $RUST_DEV_ENV/reference-projects/PRINCIPLES.md (Elon Musk's recommendations, SOLID, NASA's 10 rules) and COMMON_MISTAKES.md files are taken into account. |
|   **4** | Researcher                            |  Search for a ready-to-use library/framework in rust language for the current project's architectural, code or design requirement. If a crate has less then 10000 "Downloads all time" , then don't use it, directly ommit it.|
|   **5** | Architect                             |  This role builds the software architecture. Coordinator periodically loads this role to check the architectutal status of a project. |
|   **6** | Developer                             |  Rust code developer. Domain driven design, Clean Architecture, Test Driven Development, Data Driven Test, Nasa rules, Solid principles.  |
|   **7** | Designer                              |  UX and UI designer. |
|   **8** | Reviewer                              |  Rust Code Reviewer. |
|   **9** | Tester                                |  Rust Test Code Writer. |
|   **10** | Qa                                    |  Quality Assurance Engineer. Makes the last checks and builds the final rpm and deb package for project.|



NOTE: Kilo agent (Automatically starts Coordinator sub agent) is started by running start_agent.sh command installed by $RUST_AGENT_INFRA_DIR/harness/intall.sh script. 


### Skills Catalog (Rust, Gitea-driven)

| No. | Skill Path | Description | Agents Using |
| ----- | ----- | ----- | ----- |
| 1 | `agent-memory` | Layered memory for a small context window - plan, step results, and notes saved outside the context, checkpointed to the Gitea issue, and restored after /reset. Use it at the start of every issue, after every step, when context is above 60 percent, and when resuming an interrupted issue. | Analyzer, Architect, Coordinator, Designer, Developer, Qa |
| 2 | `architecture-assessment` | Assess the real Rust workspace architecture against the design - layers, cycles, drift - with severity. Use for Architect checkpoints and structure reviews. | Architect |
| 3 | `architecture-checkpoint` | Create a periodic Architect issue that checks architecture drift. Use after several Developer issues, before a release, or after structural changes. | Coordinator |
| 4 | `architecture-wiki` | Write the architecture overview, status page, and numbered ADRs in the wiki. Use when recording a design decision or an assessment. | Architect |
| 5 | `asd-ste100` | Use when English text must be parsed without a human to resolve ambiguity — tool descriptions, error messages, inter-agent instructions, system prompts, status reports — and misreading has a real cost, or when text reads as dense, hedged, or easy to misparse. Triggers: disambiguate, STE100 rewrite, apply Simplified Technical English, plain-language rewrite, controlled-language rewrite, rewrite so an agent cannot misread this. Not for creative or marketing copy. | Analyzer |
| 6 | `crate-download-filter` | Enforce the rule that no Rust crate under 10000 all-time downloads is used. Use whenever a dependency is proposed, reviewed, or added. | Researcher |
| 7 | `crate-search` | Find Rust crates for a need on crates.io and drop crates under 10000 all-time downloads. Use for Researcher tasks. |Researcher |
| 8 | `ddd-clean-architecture` | Define bounded contexts and layers and scaffold a four-layer Cargo workspace with layers.toml. Use when designing project or module structure. | Architect |
| 9 | `gitea-assignment-handoff` | Rules for passing an issue between Human, Coordinator, and role agents with the right owner and status labels. Use when handing off, escalating, or returning work. | Analyzer, Architect, Coordinator, Designer, Developer, Qa |
| 10 | `gitea-issues` | Read, create, comment on, label, route, and close current git project Gitea issues with the gitea-mcp tools. Use for all issue communication - picking up work, reporting, handing off. | Analyzer, Architect, Coordinator, Designer, Developer, Qa |
| 11 | `gitea-wiki` | List, read, create, and update current git project Gitea wiki pages with the gitea-mcp tools. Use to store or look up requirements, architecture pages, ADRs, specs, and status reports. | Analyzer, Architect, Coordinator, Designer, Developer, Qa |
| 12 | `graph-memory` | Find code, modules, requirements, and how they connect by querying a graphify knowledge graph instead of reading files. Use it before opening or grepping source files, when asked how things relate, and after code changes to refresh the graph. | Analyzer, Architect, Coordinator, Designer, Developer, Qa |
| 13 | `human-escalation` | Ask the Human a decision question through a blocked issue with options and a recommendation. Use for unclear, critical, or conflicting decisions. | Coordinator |
| 14 | `issue-comment-protocol` | Standard format for every agent comment on an issue - author header, what was done, result, files changed, next step. Use whenever you finish, block, or report on an issue. | Analyzer, Architect, Coordinator, Designer, Developer, Qa |
| 15 | `issue-completion` | Finish a role issue with the standard comment, status label, hand back to the Coordinator, and memory clear. Use when work is done or blocked. | Analyzer, Architect, Designer, Developer, Qa |
| 16 | `issue-polling` | Find the next open issue labeled for this agent, resuming an interrupted one first. Use when an agent starts as its own session, resets, or has no task. | Analyzer, Architect, Designer, Developer, Qa |
| 17 | `issue-triage` | Split a Human goal into small, ordered role issues with one role each and acceptance criteria. Use when the Coordinator gets a new goal, a Human answer, or a finished role issue. | Coordinator |
| 18 | `karpathy-guidelines` | Behavioral guidelines to reduce common LLM coding mistakes. Use when writing, reviewing, or refactoring code to avoid overcomplication, make surgical changes, surface assumptions, and define verifiable success criteria. |Developer, Reviewer |
| 19 | `lean-shell` | Run shell commands with small output using rtk (Rust Token Killer), with a safe fallback. Use it for every command that can print more than about 30 lines - git, cargo build, test, clippy, grep, find, ls - and when reading files. | Analyzer, Architect, Coordinator, Designer, Developer, Qa |
| 20 | `minimal-build` | Write the least code that meets the requirement, using a ponytail-style ladder before any new code, and keep each step's diff small. Use it before writing code, a new function, a dependency, or a document section, and when reviewing a diff for over-building. | Analyzer, Architect, Coordinator, Designer, Developer, Qa |
| 21 | `nasa-rules-solid` | Apply NASA's 10 rules and SOLID to Rust code. Use when writing or checking Rust for safety and design. | Developer |
| 22 | `principles-check` | Check requirements, designs, or Rust code against PRINCIPLES.md (Musk, SOLID, NASA rules) and COMMON_MISTAKES.md, with a Rust scanner. Use for Analyzer, Architect, Developer, and Reviewer checks. | Analyzer, Architect |
| 23 | `progress-tracking` | Report issue status by label and find stalled, blocked, and waiting issues. Use at the start of each Coordinator cycle and when asked where the project stands. | Coordinator |
| 24 | `release-checklist` | Run the final quality gate before release and report pass or fail. Use for Qa release tasks, before packaging. | Qa |
| 25 | `requirements-quality-check` | Check requirements or an issue for consistency, ambiguity, contradiction, completeness, redundancy, validity, relevance, accuracy, clarity, correctness, entailment, satisfiability. Use for Analyzer review tasks. | Analyzer |
| 26 | `requirements-wiki-builder` | Build and update the requirements index in the wiki from requirement lines. Use when the Coordinator asks the Analyzer to build or refresh the requirements wiki. | Analyzer |
| 27 | `role-selection` | Choose the role agent for an issue and write the Role line and owner label. Use when creating or reassigning a role issue or when the role is unclear. | Coordinator |
| 28 | `rpm-deb-packaging` | Build and verify .rpm and .deb packages with cargo-deb and cargo-generate-rpm. Use for Qa packaging tasks after the release gate passes. | Qa |
| 29 | `rust-code-review` | Review Rust changes with automatic checks and a checklist and report findings by severity. Use for Reviewer tasks. | Reviewer |
| 30 | `rust-ddd-clean-arch-dev` | Implement Rust code with DDD and Clean Architecture in the right layer with typed errors and no panics. Use for any Developer task. | Developer |
| 31 | `rust-ddd` | Create, review, and verify Domain-Driven Design (DDD) architecture in Rust projects (layered / hexagonal, Cargo workspace or single crate). Use this skill whenever the user wants to scaffold a Rust project with DDD, add a bounded context, aggregate, entity, value object, repository, domain event, or use case, or asks to check, audit, or refactor Rust code for layer violations, anemic domain models, or dependency-rule breaks. Trigger even if they only say "clean architecture", "hexagonal", "ports and adapters", "domain layer", or "bounded context" in a Rust context. | Developer |
| 32 | `rust-tdd` | TDD workflow for Rust with data-driven tests and a fmt, clippy, test gate. Use when writing behavior, fixing bugs, or checking that code is green. | Developer |
| 33 | `rust-test-writing` | Write Rust unit, integration, and data-driven tests from requirements and find untested functions. Use for Tester tasks. | Tester |
| 34 | `step-protocol` | Split every task into think, plan, execute small steps, and split again when a step fails or is too big. Use it for every issue and every task that cannot be finished in one short attempt, in any role. | Analyzer, Architect, Coordinator, Designer, Developer, Qa |
| 35 | `terse-mode` | Write notes, step results, and agent-to-agent comments in short caveman style to save tokens, and compress memory files. Use it for mem.py notes and results, checkpoint and handoff comments, and when a memory file or AGENTS.md grows too large. Not for Human-facing text, requirements, code, or commits. | Analyzer, Architect, Coordinator, Designer, Developer, Qa |
| 36 | `ux-ui-design` | Produce UX flows and UI specs (screens, states, accessibility) as wiki pages. Use for Designer tasks. | Designer |

#### How we improved the skills and agents in the harness 

I entered the following prompts in the claude.ai web prompt to improve the md files :

1. as i only have 64kb context size, i need to implement agents.md files, skills that will use different levels of agentic memories, and try to split every step of the work into smaller parts if it can not finish in the first attempt. splitting would be like  ( think, plan, execute small pieces step by step) 
2. also can you make use of rtk, caveman , graphify , ponytail in your md files and scripts, and reprepare the harness as zip file?
3. cut the skills in https://github.com/leonardomso/rust-skills into smaller skills so that i can load them, and execute them one by one , my maximum context size is 64k

Claude.ai gave the following response with the corrected scripts zip file :

>**1. Small context**
>The zip now has 36 skills, all validated. AGENTS.md is about 800–900 tokens, each skill is 350–700 tokens, and all skill descriptions together are about 1.5K tokens.
>I assumed "64kb" means a 64K-token window. If it is really 64 KB (about 16K tokens), set MEM_CONTEXT_TOKENS=16000 and link only the skills each role needs.
>Layered memory. The new agent-memory skill and its mem.py script keep only the current step in context. Plan, step results and notes live in .mem/<issue>/, which survives /reset. A checkpoint comment on >the Gitea issue lets a lost workspace or another agent resume. The wiki and a graphify graph hold project knowledge, and roles and principles are read in slices.
>Think, plan, execute. The new step-protocol skill plans at most 8 steps, about 8K tokens of work each. A step that fails twice, touches more than 3 files, or prints more than 150 lines is split into 2–4 >smaller steps. Missing information makes the issue blocked. Both AGENTS.md files tell the agent to checkpoint every 3 steps, at 60% context after the step, and at 75% to checkpoint, /reset, then resume. >The heavy role skills each have a "Steps" section with their own split points.
>Bounded output. get --brief shows the body plus the last 5 comments. The wiki is read in 6000-character parts, and role files, scanners and status reports are capped.

>**2. The four tools**
>All four are optional, and every script falls back to plain behaviour without them.
>Tool	Used in
>rtk	rt.sh, which cargo and git go through, including the gate and packaging scripts
>graphify	graph.sh, used before reading code
>caveman	terse-mode for notes and agent comments, with short rules inline in AGENTS.md; Human-facing text, requirements, code and commits stay normal
>ponytail	minimal-build, a ladder plus a 150-added-lines-per-step check
>I looked up each tool's documentation for the commands. The README has the install lines, and check_tools.sh shows which are installed.
>Testing
>mem.py, including checkpoint and restore in a fresh workspace, the Gitea scripts and the capped outputs were tested against a mock Gitea.
>rtk, graphify, caveman and ponytail were not installed here, so only the fallback paths ran.
>The rtk and graphify command forms come from their documentation.
>Cargo is not installed here, so the cargo-based scripts are still untested.
>For your setup
>clear_worker.sh should not delete .mem/ for an issue that is still in progress. If it does, mem.py start restores from the last checkpoint.
>Install caveman and ponytail by copying their skills into .kilo/skills/.
>Run graphify once with /graphify . before the first graph.sh build.

>**3. rust-skills split**
>I split the https://github.com/leonardomso/rust-skills repo into 44 small skills plus a router, packed in rust-skills-split.zip. The whole thing is about 270k tokens, so the cut is much finer than one skill per category. Each module is about 3.5–7.5k tokens by a rough chars/3.3 estimate; I couldn't count with a real tokenizer here. One module plus the router and some code to review fits comfortably in 64k.
>How I cut it
>Router: rust-00-router is the only skill to load first, at about 1.4k tokens. It has the one-at-a-time runbook, which modules suit which task, and a table of all modules with their sizes.
>Modules: rust-01-… to rust-44-… follow the upstream priority order, from Ownership, Errors, Memory and Unsafe down to Linting and Anti-patterns. Big categories are split into parts, for example Async into 4 parts and Memory, API Design and Testing into 3 each. Small ones are combined, such as Conversions with Const.
>Rule text: The rule text is verbatim. Each module has a rule list at the top, then every rule's Why, Bad and Good sections.
>See Also links: I replaced the links with a plain Related: rule-ids line, because the per-rule files they pointed to no longer exist as separate files.
>Checks: All 265 rules appear exactly once. The largest module is 24.9 KB.
>Extra files: The zip also includes the upstream MIT LICENSE and a manifest.json with per-module sizes.
>How to run them one by one
>Load the router and pick modules for your task. Ownership and Errors are first for any Rust code.
>Load one module, check your code against it, and write down short findings as rule-id | location | fix.
>Drop the module and keep only the findings list.
>Load the next module and repeat. At the end, merge the findings and apply the fixes.
>Keep the code you review to roughly 10k tokens per pass, so a large file should be reviewed function by function.
>The split inside a category follows the upstream index order, which is mostly thematic, so some parts group related rules better than others. If you want tighter themes, for example Async split into channels, cancellation and core, or smaller modules around 4k tokens, you can regenerate it.



#### Manual Modifications

1. We inserted the following rule into the Coordinator.md file
   - Write "what did you decide that i did not tell you to decide" into the gitea wiki of the project.

2. In worker AGENTS.md file, i inserted the following lines :
   - If your context gets filled while doing your work, assign the gitea issue back to coordinator,  for split.

2. I moved modules of the rust-skills under the rust-code-review/references directory.
    

## Example usage of this harness to develop a Purchase List Application in Rust.

0. You have to configure the GITEA_AGENT_PERSONAL_ACCESS_TOKEN, API_KEY . You may find them in previous sections.

1. Open the terminal and source the rust-agent-infra/release file, source the release file in rust-dev-env.

2. Run GITEA : "cd $RUST_DEV_ENV/devops/bin/ ; ./run_gitea.sh"

3. Start LLM services : "cd $RUST_AGENT_INFRA_DIR/services && ./00.main.sh"

4. Create the agent workspace :  "mkdir -p ~/agent-workspace/"

5. Clone the repository into agent workspace : " cd ~/agent-workspace; git clone http://agent:qwe132**@localhost:13000/rust-agentic-org/purchase.git"

6. Go to project directory : "cd  ~/agent-workspace/purchase "

7. Install Harness : "$RUST_AGENT_INFRA_DIR/harness/install.sh ~/agent-workspace/purchase"
  
8. Login as human to the gitea

9. Select "purchase"  project from Explorer link found on top of the page.

10. Click on the "wiki" link , and click on the "Create first page" button

10.1. Set the Title as "01-Project-Definition"

10.2. Copy the content of the file $RUST_AGENT_INFRA_DIR/example-usage/01.project_definition.md and paste it to body part.

10.3. Click "Save" button.

11. Assign a task to agent with Subject "Start the implementation" and the body of the task is the same , "Start the implementation" . 
 
12. Start Kilo Code CLI Agent : 
   - Open a new terminal, 
   - source the release file in rust-dev-env (source ~/sdk/rust-dev-env/release )
   - source the rust-agent-infra/release file ( source ~/workspace/rust-agent-infra/release )
   - go to project directory ( cd ~/agent-workspace/purchase )
   - start the agent. ( ./start_agent.sh)
   - write "Start coordinator agent" in kilo input.
 
 


