#!/bin/bash
set -euo pipefail

if [ "$RUST_AGENT_INFRA_DIR" = "" ]
then
        echo "no RUST_AGENT_INFRA_DIR envvironment variable found. Please source the 'release' file found in the parent directory of this script (rust-agent-infra/release)"
        exit 1
fi

if [ $# -lt 1 ]
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

echo "You are in $WORKSPACE, we will create two sub directories for coordinator and for worker. "


mkdir -p .kilo

cp  -Rf $RUST_AGENT_INFRA_DIR/harness/agents .kilo/agents
cp  -Rf $RUST_AGENT_INFRA_DIR/harness/skills .kilo/skills

    
echo "
 export GITEA_OWNER=rust-agentic-org
 export GITEA_REPO=project-01 
 export HUMAN_USER=human1 
 export COORDINATOR_USER=coordinator1 
 export MEM_CONTEXT_TOKENS=64000   # per agent workspace
 export GITEA_ACCESS_TOKEN='$COORDINATOR1_PERSONAL_ACCESS_TOKEN'   # in the coordinator process
 export MEM_DIR='$WORKSPACE/.mem'
 kilo config check
 #KILO_CONFIG=.kilo/kilo.jsonc caveman run -- kilo config check
 #KILO_CONFIG=.kilo/kilo.jsonc caveman run -- kilo debug config
 caveman run -- kilo --model local//local_model
" > start_agent.sh

chmod +x start_agent.sh
    
if [ ! -f .kilo/kilo.jsonc ]
then
  cp $RUST_AGENT_INFRA_DIR/harness/kilo.jsonc .kilo/kilo.jsonc
fi
     
PONYTAIL_MJS=$(find $RUST_AGENT_INFRA_DIR/dev-tools -name ponytail.mjs)
echo "PONYTAIL_MJS=$PONYTAIL_MJS"
perl -pi -e "s#PONYTAIL_MJS#$PONYTAIL_MJS#g" .kilo/kilo.jsonc
echo "RUST_DEV_ENV=$RUST_DEV_ENV"
perl -pi -e "s#RUST_DEV_ENV#$RUST_DEV_ENV#g" .kilo/kilo.jsonc
GITEA_ACCESS_TOKEN=$COORDINATOR1_PERSONAL_ACCESS_TOKEN
echo "GITEA_ACCESS_TOKEN=$GITEA_ACCESS_TOKEN"
perl -pi -e "s#_GITEA_ACCESS_TOKEN_#$GITEA_ACCESS_TOKEN#g" .kilo/kilo.jsonc
echo "OPENAI_API_KEY=$OPENAI_API_KEY"
perl -pi -e "s#OPENAI_API_KEY#$OPENAI_API_KEY#g" .kilo/kilo.jsonc
     


cp -f $RUST_AGENT_INFRA_DIR/harness/AGENTS.md  .
 


