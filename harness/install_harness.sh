#!/bin/bash
# install.sh [--link] [--force] [RUST_AGENT_INFRA_DIR]
# Install the skills into $RUST_AGENT_INFRA_DIR/harness. Existing skills are kept unless --force.
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


}

create_agent_workspaces coordinator
create_agent_workspaces worker






for dir in modes-agents workflows-commands skills-skills
do
        rust_agent_infra_harness=$(echo $dir | cut -d- -f1)
        kilo_harness=$(echo $dir | cut -d- -f2)
        echo "Mapping files in the rust-agent-infra harness directory : $rust_agent_infra_harness TO the  kilo harness directory : $kilo_harness ...."
        for sub in $RUST_AGENT_INFRA_DIR/harness/$rust_agent_infra_harness/*
        do
            f=$(basename $sub)
            mkdir -p .kilo/$kilo_harness
            if [ ! -e .kilo/$kilo_harness/$f ]
            then
                ln -s $sub .kilo/$kilo_harness/$f
            fi
        done
done


here="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
mode=copy; force=0; infra="${RUST_AGENT_INFRA_DIR:-}"
for arg in "$@"; do
  case "$arg" in
    --link) mode=link;;
    --force) force=1;;
    -h|--help) sed -n '2,3p' "$0"; exit 0;;
    *) infra="$arg";;
  esac
done
[ -n "$infra" ] || { echo "error: give RUST_AGENT_INFRA_DIR as argument or environment variable" >&2; exit 64; }
h="$infra/harness"
install_group() { # source-dir target-dir
  local src="$1" dst="$2"
  mkdir -p "$dst"
  for s in "$src"/*/; do
    local name; name="$(basename "$s")"
    if [ -e "$dst/$name" ] || [ -L "$dst/$name" ]; then
      if [ $force -eq 1 ]; then rm -rf "$dst/$name"; else echo "keep   $dst/$name (exists, use --force)"; continue; fi
    fi
    if [ "$mode" = link ]; then ln -s "${s%/}" "$dst/$name"; else cp -r "${s%/}" "$dst/$name"; fi
    echo "$mode   $dst/$name"
  done
}
install_group "$here/base-skills"        "$h/base-skills"
install_group "$here/coordinator-skills" "$h/coordinator-skills"
install_group "$here/worker-skills"      "$h/worker-skills"
install_group "$here/library/skills"     "$h/library/skills"
mkdir -p "$h/library/roles"
for f in "$here"/library/roles/*.md; do
  t="$h/library/roles/$(basename "$f")"
  if [ -e "$t" ] && [ $force -eq 0 ]; then echo "keep   $t (exists, use --force)"; else cp "$f" "$t"; echo "copy   $t"; fi
done
mkdir -p "$h/agents-md"
for r in coordinator worker; do mkdir -p "$h/agents-md/$r"; if [ -e "$h/agents-md/$r/AGENTS.md" ] && [ $force -eq 0 ]; then echo "keep   $h/agents-md/$r/AGENTS.md (exists, use --force)"; else cp "$here/agents-md/$r/AGENTS.md" "$h/agents-md/$r/AGENTS.md"; echo "copy   $h/agents-md/$r/AGENTS.md"; fi; done
find "$h" -path '*/scripts/*' -type f \( -name '*.sh' -o -name '*.py' \) -exec chmod +x {} + 2>/dev/null || true
cat <<MSG

Done. Next steps:
 1. Add the linking and environment lines from README.md to start_agents.sh.
 2. Run once: python3 $h/base-skills/gitea-issues/scripts/gitea.py ensure-labels
MSG
