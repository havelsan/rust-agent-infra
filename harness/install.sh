#!/bin/bash

if [ "$RUST_AGENT_INFRA_DIR" = "" ]
then
        echo "no RUST_AGENT_INFRA_DIR environment variable found. Please source the 'release' file found in the parent directory of this script (rust-agent-infra/release)"
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
	echo "workspace $WORKSPACE can not be the same as RUST_AGENT_INFRA_DIR=$RUST_AGENT_INFRA_DIR"
	exit 1
fi

PROJECT_NAME=$(basename $WORKSPACE)

mkdir -p $WORKSPACE

cd $WORKSPACE

echo "Applying $RUST_AGENT_INFRA_DIR/harness to this directory ..."

echo "You are in $WORKSPACE"

mkdir -p .kilo

cp  -Rf $RUST_AGENT_INFRA_DIR/harness/agents .kilo/agents
cp  -Rf $RUST_AGENT_INFRA_DIR/harness/skills .kilo/skills
cp  -Rf $RUST_AGENT_INFRA_DIR/harness/rules .kilo/rules
    
echo "

# rtk init --agent kilocode
# graphify kilo install
# graphify .
# graphify cluster-only .
	
 kilo config check
 #KILO_CONFIG=.kilo/kilo.jsonc caveman run -- kilo config check
 #KILO_CONFIG=.kilo/kilo.jsonc caveman run -- kilo debug config
 caveman run -- kilo --model local//local_model
" > start_agent.sh

chmod +x start_agent.sh
    
cp -f $RUST_AGENT_INFRA_DIR/harness/kilo.jsonc .kilo/kilo.jsonc

cp -f $RUST_AGENT_INFRA_DIR/harness/AGENTS.md  .
     
PONYTAIL_MJS=$(find $RUST_AGENT_INFRA_DIR/dev-tools -name ponytail.mjs)
echo "PONYTAIL_MJS=$PONYTAIL_MJS"
perl -pi -e "s#PONYTAIL_MJS#$PONYTAIL_MJS#g" .kilo/kilo.jsonc
echo "RUST_DEV_ENV=$RUST_DEV_ENV"
perl -pi -e "s#RUST_DEV_ENV#$RUST_DEV_ENV#g" .kilo/kilo.jsonc
echo "GITEA_ACCESS_TOKEN=$GITEA_AGENT_PERSONAL_ACCESS_TOKEN"
perl -pi -e "s#_GITEA_ACCESS_TOKEN_#$GITEA_AGENT_PERSONAL_ACCESS_TOKEN#g" .kilo/kilo.jsonc
echo "GITEA_ORG=$GITEA_ORG"
perl -pi -e "s#_GITEA_ORG_#$GITEA_ORG#g" .kilo/kilo.jsonc AGENTS.md
echo "GITEA_OWNER=$GITEA_OWNER"
perl -pi -e "s#_GITEA_OWNER_#$GITEA_OWNER#g" .kilo/kilo.jsonc AGENTS.md
echo "GITEA_REPO=$PROJECT_NAME"
perl -pi -e "s#_GITEA_REPO_#$PROJECT_NAME#g" .kilo/kilo.jsonc AGENTS.md
echo "OPENAI_API_KEY=$OPENAI_API_KEY"
perl -pi -e "s#OPENAI_API_KEY#$OPENAI_API_KEY#g" .kilo/kilo.jsonc


