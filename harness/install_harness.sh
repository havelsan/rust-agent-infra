#!/bin/bash
set -euo pipefail

if [ "$RUST_AGENT_INFRA_DIR" = "" ]
then
        echo "no RUST_AGENT_INFRA_DIR envvironment variable found. Please source the 'release' file found in the parent directory of this script (rust-agent-infra/release)"
        exit 1
fi

if [ $# -lt 2 ]
then
       echo "Usage: $0 <project_agent_workspace_dir>"
       echo "Example: $0 $HOME/agent-workspace/X-project"
       echo "Example: $0 ."
       exit 1
fi
 
WORKSPACE=$(realpath $1)

if [ "$WORKSPACE" = "$RUST_AGENT_INFRA_DIR/harness" -o "$WORKSPACE" = "$RUST_AGENT_INFRA_DIR" ]
then
	echo "Go to the project's workspace please ..."
	exit 1
fi

cd $WORKSPACE

echo "Applying $RUST_AGENT_INFRA_DIR/harness to this directory ..."

echo "You are in $WORKSPACE, we will create two sub directories for coordinator and for worker, then decorate the .kilo directories and start a kilo agent for coordinator and worker "

create_agent_workspaces (){
    
    agent_type=$1
    
    if [ ! -f $agent_type-workspace/AGENTS.md ]
    then
         echo "$agent_type-workspace/AGENTS.md already exists, this script only installs into an empty directory "
         return
    fi     
    
    mkdir -p $agent_type-workspace/.kilo/agents
    mkdir -p $agent_type-workspace/.kilo/skills
    
    GITEA_ACCESS_TOKEN=$COORDINATOR1_PERSONAL_ACCESS_TOKEN
    
    if [ $agent_type = "worker" ]
    then
        GITEA_ACCESS_TOKEN=$WORKER1_PERSONAL_ACCESS_TOKEN
    fi
     
    echo "
      export GITEA_OWNER=rust-agentic-org
      export GITEA_REPO=project-01 
      export HUMAN_USER=human1 
      export COORDINATOR_USER=coordinator1 
      export WORKER_USER=worker1
      export MEM_CONTEXT_TOKENS=32000   # per agent workspace
      export GITEA_ACCESS_TOKEN='$GITEA_ACCESS_TOKEN'   # in the coordinator process
      export MEM_DIR='$WORKSPACE//$agent_type-workspace/.mem'

      caveman run -- kilo
    " > $agent_type-workspace/start_agent.sh
    
     chmod +x $agent_type-workspace/start_agent.sh

     cp -f $RUST_AGENT_INFRA_DIR/harness/agents-md/$agent_type/AGENTS.md  $agent_type-workspace/
     cp -rf $RUST_AGENT_INFRA_DIR/harness/$agent_type-skills/*  $agent_type-workspace/.kilo/skills/

     ## library is not linked, because it is used directory from $RUST_AGENT_INFRA_DIR/harness/library
}

create_agent_workspaces coordinator
create_agent_workspaces worker


#Next steps:
# 1. Add the linking and environment lines from README.md to start_agents.sh.
# 2. Run once: python3 $h/base-skills/gitea-issues/scripts/gitea.py ensure-labels
#MSG


