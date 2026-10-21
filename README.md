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
3. How we use deep seek harness and kilo-code: [DEEP_SEEK_HARNESS_USAGE](docs/adrs/adr-003-deepseek-harness.md)
4. How we use Plugins/APIs and MCPs : [MCP_and_HARNESS](docs/adrs/aadr-004-mcp-vs-plugins.md)
5. How we do context token reduction :  [CONTEXT_TOKEN_REDUCTION](docs/adrs/adr-005-context-token-reduction-tools.md)


##  Installation of Services and Tools 

Clone this repository into your wworkspace directory, source the release file and run the ~/workspace/rust-agent-infra/install/00.main.sh  script.
    
##  Starting Services

After installing services and tools, source the ~/workspace/rust-agent-infra/release file then start services by running the ~/workspace/rust-agent-infra/services/00.main.sh script.


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
		> Make a step by step plan for to improve the code in simple_calculator project using the code review notes in ~/agentspace/agent-managed-rust-project/simple_calculator/issues/REVIEW-001.md and write the into ~/agentspace/agent-managed-rust-project/simple_calculator/plans/PLAN-01.md.  Steps of the plan should be as small as possible so that we can fit into 32k context :) 
			> The LLM Says : Plan generated.
		> Execute each step one by one. Write the executed steps of the plan into ~/agentspace/agent-managed-rust-project/simple_calculator/plans/PLAN-REPORT-01.md
			> The LLM Says : Compaction exhausted: context still exceeds model limits after 3 attempts


As you see from the LLM response, LLM could not make the improvement, so we tried to reduce the number of tokens, wihch is shown in next section.

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

0. Switch to a user that can NOT execute sudo commands, and also that does NOT have git master/tag privileges.
1. Clone a copy of your project into a directory.
2. Checkout a branch that "kilo code agent" can commit. (or even push)
3. Source the release file : ~workspace/rust-agent-infra/release 
4. Run the harness installation script : ( ~workspace/rust-agent-infra/harness/install_kilo_harness.sh)  

This command create .kilo directory if it does not exists , and creates links (if not exists) to the skill/mode/workflow files found in the ~/workspace/rust-agent-infra/harness directory.

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
	


## Building Harness using Skills + Modes(Agents) + Memory + MCPs

We build a harness for our development environment.  We will use the following main parts in our development environment, so the harness will be built around them :

1. rust
2. gitea
3. kilo code

### Rust Check List

Install [rust-dev-env](https://github.com/havelsan/rust-dev-env) in $HOME/sdk/rust-dev-env  

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
           - We assume that the token in this command was generated in the first step by reading the devops/README.md 
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

2. Create Users (human1, coordinator1, worker1) :  

   1. Goto http://localhost:13000/ GITEA in browser.
   2. Login as admin (if you follow rus-dev-env , default is adm001/adm001+++ ) 
   3. Click on the icon on the right-top of  most the page.
   4. Click "site administration"
   5. Click on the "Identity & Access" menu item on the left menu.
   6. Click on the "User Accounts" menu item
   7. Click on the "Create User Account" button on the right-top of the page.
        1. Authentication Source : local
        2. User visibility : public
        3. User name : human1
        4. Email : human1@localhost.org  
        5. Password : human1+++
        6. Un check the "Require user to change the password"
        7. click "Create user account"
   8. create personal access tokens
        1. Login as human1
        2. Click on the rigt-top most icon on the page 
        3. Click on the "settings" menu item
        4. Click on the "Applications" menu item
        5. Generate new token
            1. Token Name : HUMAN1_PERSONAL_ACCESS_TOKEN
            2. Repository and Organization Access : All
            3. Token Permissions : (activitypub, issue, misc, notification, organization, package, repository, user)  , (  Read and Write )
            4. Click on the "Create Token" button
            5. copy the token appearing on the top of the page.
            6. insert the "export HUMAN1_PERSONAL_ACCESS_TOKEN=a33d9663ceab39378746095a5919ff5c1d384044" line in the $HOME/workspace/rust-agent-infra/release 
   9. In the end the following three lines should inserted in the $HOME/workspace/rust-agent-infra/release file.

   
> export HUMAN1_PERSONAL_ACCESS_TOKEN=a33d9663ceab39378746095a5919ff5c1d384044

> export COORDINATOR1_PERSONAL_ACCESS_TOKEN=d8220143aa17a56e5811d61482a71bdd12791b94

> export WORKER1_PERSONAL_ACCESS_TOKEN=8bd5ca5990103e773e67d35c2b981e48bbbeb49b


3. Create project-01 Repository :

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
      8. Add worker1, coordinator1, human1 users to this team using "Add Team Member" 
   6. Return back to the "rust-agentic-org" page using Explore > Organizations > rust-agentic-org
   7. Create a new repository using "Create New Repository" button
      1. Owner : rust-agentic-org
      2. Repository name : project-01
      3. Visibility: NOT CHECKED: Mahe repository Private. ( The repository is public)
      4. Description : Project 01
      5. Tepmplate :  DID_NOT_SELECT_ANYTHING
      6. Issue Labels : Advanced
      7. .gitignore : Rust
      8. License : 0BSD
      9. Readme : Default
      10. Default Branch: main
      11. Object Format: sha1
      12. Template : NOT_CHECKED: Make repository a template.
      13. Click on the Create Repository
      

  
### Agents and Roles

We currently assume that a team of agents (agentic-team composed of human, coordinator, worker) will use project-01 git repository's issues and wiki in gitea to communicate each other. When a Human assigns an issue to Coordinator the project starts. Coordinator may assign an issue to human if it can not determine what to do. 

Coordinator and Worker agents are started by running $RUST_AGENT_INFRA_DIR/harness/start_agents.sh command which does the following :
1. Creates two distinct workspace directories in the current project's directory for coordinator and worker. ( e.g. $HOME/workspace/my-project/worker-space and $HOME/workspace/my-project/coordinator-space). Each workspace has it's own .kilo/kilo.jsonc file containing corresponding GITEA_ACCESS_TOKEN parameter name as COORDINATOR1_PERSONAL_ACCESS_TOKEN and WORKER1_PERSONAL_ACCESS_TOKEN respectively. 
2. Links base skills from $RUST_AGENT_INFRA_DIR/harness/base-skills directory into .kilo/skills directory such as gitea related skills.


| Agent No | Agent Name                             | Description               |
| ------: | ------------------------------------- | ---------------------- |
|   **1** | Human                                 |  Starts the project by assigning an issue to the coordinator. Every critical decision should be asked to this role through the gitea issues.|
|   **2** | Coordinator                           |  Central coordination agent. Owns project-level workflow; communicates with the Human and all agents through Gitea Issues; assigns, tracks, and escalates work. Coordinator assigns the issue to the worker. Also the role to use while resolving the issue is indicated within the issue by coordinator. |
|   **3** | Worker                                |  After starting worker agent, it continously reads gitea issues of project-01 and loads the role indicated within the issue from the library found in the $RUST_AGENT_INFRA_DIR/harness/library/roles  directory. After finishing the work the worker changes the state of the issue that it works on and enters a comment about what it did. Lastly it calls $RUST_AGENT_INFRA_DIR/harness/clear_worker.sh script, calls /reset and /reload command.|

 
| Role No | Role Name                             | Description               |
| ------: | ------------------------------------- | ---------------------- |
|   **1** | Analyzer                              |  Analyze the assigned issue or document link assigned using a gitea issue, checks consistency, ambiguity, contradiction, completeness, redundancy, validity, relevance, accuracy, clarity, correctness, entailment, satisfiability. Build wiki for requirements of a project if the coordinator asks for it. Also check for asd-ste100 using asd-ste10-skill that can be found in $RUST_AGENT_INFRA_DIR/harness/library/skills. Also $RUST_DEV_ENV/reference-projects/PRINCIPLES.md (Elon Musk's recommendations, SOLID, NASA's 10 rules) and COMMON_MISTAKES.md files are taken into account. |
|   **2** | Researcher                            |  Search for a ready-to-use library/framework in rust language for the current project's architectural, code or design requirement. If a crate has less then 10000 "Downloads all time" , then don't use it, directly ommit it.|
|   **3** | Architect                             |  This role builds the software architecture. Coordinator periodically loads this role to check the architectutal status of a project. |
|   **4** | Developer                             |  Rust code developer. Domain driven design, Clean Architecture, Test Driven Development, Data Driven Test, Nasa rules, Solid principles.  |
|   **5** | Designer                              |  UX and UI designer. |
|   **6** | Reviewer                              |  Rust Code Reviewer. |
|   **7** | Tester                                |  Rust Test Code Writer. |
|   **8** | Qa                                    |  Quality Assurance Engineer. Makes the last checks and builds the final rpm and deb package for project.|


### Skills Catalog (Rust, Gitea-driven)

Skills are folders with a `SKILL.md`. Base skills are linked into every workspace's `.kilo/skills` by `start_agents.sh`. Role skills are loaded by the Worker together with the role file from `$RUST_AGENT_INFRA_DIR/harness/library/roles`.

**Status legend:** `Existing` = already mentioned in your setup. `Proposed` = suggested, not yet written.

#### 1. Base skills (all agents)

Location: `$RUST_AGENT_INFRA_DIR/harness/base-skills/`

| ID | Skill | Description | Used by | 
| --- | --- | --- | --- | --- |
| B-01 | `gitea-issues` | List, read, create, comment on, assign, and change state of issues in project-01 using the agent's own `GITEA_ACCESS_TOKEN`. | Human, Coordinator, Worker | 
| B-02 | `gitea-wiki` | Read, create, and update wiki pages in project-01. | Coordinator, Worker | 
| B-03 | `issue-comment-protocol` | Standard comment format: what was done, files or pages changed, result, next step. Keeps handoffs readable for Human and other agents. | Coordinator, Worker | 
| B-04 | `gitea-assignment-handoff` | Rules for assigning an issue to Human, Coordinator, or Worker, and for changing state (open, in progress, done, blocked). | Coordinator, Worker | 

#### 2. Coordinator skills

Location: `<coordinator-space>/.kilo/skills/`

| ID | Skill | Description | Used by | 
| --- | --- | --- | --- | --- |
| C-01 | `issue-triage` | Read a new Human issue, split it into work items, and create the Worker issues. | Coordinator | 
| C-02 | `role-selection` | Choose the role for each Worker issue and write it clearly in the issue body (e.g. `Role: Analyzer`). | Coordinator | 
| C-03 | `human-escalation` | Detect an unclear or critical decision, write the question with options, and assign the issue to Human. | Coordinator | 
| C-04 | `progress-tracking` | Track open and blocked issues, find stalled work, and report status in an issue or wiki page. | Coordinator | 
| C-05 | `architecture-checkpoint` | Create periodic issues for the Architect role to check the architectural status of the project. | Coordinator | 

#### 3. Worker skills

Location: `<worker-space>/.kilo/skills/`

| ID | Skill | Description | Used by | 
| --- | --- | --- | --- | --- |
| W-01 | `issue-polling` | Continuously read assigned issues of project-01 and pick the next one to work on. | Worker | 
| W-02 | `role-loader` | Read the role named in the issue and load it from `$RUST_AGENT_INFRA_DIR/harness/library/roles`. | Worker | 
| W-03 | `issue-completion` | Change the issue state, add the result comment, and assign back to Coordinator when needed. | Worker | 
| W-04 | `worker-reset` | Run `$RUST_AGENT_INFRA_DIR/harness/clear_worker.sh`, then `/reset` and `/reload`. | Worker | 

#### 4. Role skills (loaded by Worker)

Location: `$RUST_AGENT_INFRA_DIR/harness/library/skills/`

| ID | Role | Skill | Description | 
| --- | --- | --- | --- | --- |
| R-01 | Analyzer | `asd-ste100` | Check text against ASD-STE100 Simplified Technical English. | 
| R-02 | Analyzer | `requirements-quality-check` | Check consistency, ambiguity, contradiction, completeness, redundancy, validity, relevance, accuracy, clarity, correctness, entailment, and satisfiability of an issue or linked document. | 
| R-03 | Analyzer | `requirements-wiki-builder` | Build and update the project requirements wiki when the Coordinator asks. | 
| R-04 | Analyzer | `principles-check` | Check work against `$RUST_DEV_ENV/reference-projects/PRINCIPLES.md` (Elon Musk's recommendations, SOLID, NASA's 10 rules) and `COMMON_MISTAKES.md`. | 
| R-05 | Researcher | `crate-search` | Find a ready-to-use Rust crate for an architecture, code, or design requirement. | 
| R-06 | Researcher | `crate-download-filter` | Reject any crate with fewer than 10000 "Downloads all time". Report only crates that pass. | 
| R-07 | Architect | `architecture-assessment` | Review the current architecture against requirements. Report gaps, risks, and drift. | 
| R-08 | Architect | `architecture-wiki` | Write architecture pages and decision records (ADR) in the wiki. | 
| R-09 | Architect | `ddd-clean-architecture` | Define bounded contexts, layers, and dependency rules for Rust projects. | 
| R-10 | Developer | `rust-ddd-clean-arch-dev` | Implement Rust code with Domain-Driven Design and Clean Architecture. | 
| R-11 | Developer | `rust-tdd` | Test Driven Development workflow, including data-driven tests. | 
| R-12 | Developer | `nasa-rules-solid` | Apply NASA's 10 rules and SOLID principles while coding. | 
| R-13 | Designer | `ux-ui-design` | Produce UX flows and UI designs and attach them to the issue or wiki. | 
| R-14 | Reviewer | `rust-code-review` | Review Rust code for correctness, style, `clippy` findings, principles, and common mistakes. | 
| R-15 | Tester | `rust-test-writing` | Write unit, integration, and data-driven tests for Rust code. | 
| R-16 | Qa | `release-checklist` | Run the final quality checks before release. | 
| R-17 | Qa | `rpm-deb-packaging` | Build the final `.rpm` and `.deb` packages (e.g. with `cargo-generate-rpm` and `cargo-deb`). | 

#### 5. Role to skill matrix

| Role | Base skills | Role skills |
| --- | --- | --- |
| Human | B-01 | — |
| Coordinator | B-01 to B-04 | C-01 to C-05 |
| Worker (always) | B-01 to B-04 | W-01 to W-04 |
| Analyzer | (Worker set) | R-01, R-02, R-03, R-04 |
| Researcher | (Worker set) | R-05, R-06 |
| Architect | (Worker set) | R-07, R-08, R-09 |
| Developer | (Worker set) | R-10, R-11, R-12 |
| Designer | (Worker set) | R-13 |
| Reviewer | (Worker set) | R-14 (plus R-04) |
| Tester | (Worker set) | R-15 (plus R-11) |
| Qa | (Worker set) | R-16, R-17 |


#### Improve the skills and agents in the harness 

I entered the following prompts in the claude.ai web prompt to improve the md files :

1. as i only have 32kb context size, i need to implement agents.md files, skills that will use different levels of agentic memories, and try to split every step of the work into smaller parts if it can not finish in the first attempt. splitting would be like  ( think, plan, execute small pieces step by step) 
2. also can you make use of rtk, caveman , graphify , ponytail in your md files and scripts, and reprepare the zip file?

Claude.ai gave the following response with the corrected scripts zip file :
The zip now has 35 skills, all validated. AGENTS.md is about 800–900 tokens, each skill is 350–700 tokens, and all skill descriptions together are about 1.5K tokens.
I assumed "32kb" means a 32K-token window. If it is really 32 KB (about 8K tokens), set MEM_CONTEXT_TOKENS=8000 and link only the skills each role needs.
1. Small context
Layered memory. The new agent-memory skill and its mem.py script keep only the current step in context. Plan, step results and notes live in .mem/<issue>/, which survives /reset. A checkpoint comment on the Gitea issue lets a lost workspace or another agent resume. The wiki and a graphify graph hold project knowledge, and roles and principles are read in slices.
Think, plan, execute. The new step-protocol skill plans at most 8 steps, about 4K tokens of work each. A step that fails twice, touches more than 3 files, or prints more than 150 lines is split into 2–4 smaller steps. Missing information makes the issue blocked. Both AGENTS.md files tell the agent to checkpoint every 3 steps, at 60% context after the step, and at 75% to checkpoint, /reset, then resume. The heavy role skills each have a "Steps" section with their own split points.
Bounded output. get --brief shows the body plus the last 5 comments. The wiki is read in 6000-character parts, and role files, scanners and status reports are capped.

2. The four tools
All four are optional, and every script falls back to plain behaviour without them.
Tool	Used in
rtk	rt.sh, which cargo and git go through, including the gate and packaging scripts
graphify	graph.sh, used before reading code
caveman	terse-mode for notes and agent comments, with short rules inline in AGENTS.md; Human-facing text, requirements, code and commits stay normal
ponytail	minimal-build, a ladder plus a 150-added-lines-per-step check
I looked up each tool's documentation for the commands. The README has the install lines, and check_tools.sh shows which are installed.

Testing
mem.py, including checkpoint and restore in a fresh workspace, the Gitea scripts and the capped outputs were tested against a mock Gitea.
rtk, graphify, caveman and ponytail were not installed here, so only the fallback paths ran.
The rtk and graphify command forms come from their documentation.
Cargo is not installed here, so the cargo-based scripts are still untested.

For your setup
clear_worker.sh should not delete .mem/ for an issue that is still in progress. If it does, mem.py start restores from the last checkpoint.
Install caveman and ponytail by copying their skills into .kilo/skills/.
Run graphify once with /graphify . before the first graph.sh build.


## Example usage of this harness to develop a tetris game development in Rust on Linux Gnome.






