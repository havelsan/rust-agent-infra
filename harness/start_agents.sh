if [ "$RUST_AGENT_INFRA_DIR" = "" ]
then
	echo "no RUST_AGENT_INFRA_DIR envvironment variable found. Please source the 'release' file found in the parent directory of this script (rust-agent-infra/release)"
	exit 1
fi

echo "Applying $RUST_AGENT_INFRA_DIR/harness to this directory ..."

CURRENT_DIR=$(pwd)

echo "You are in $CURRENT_DIR, we will create two sub directories for coordinator and for worker, then decorate the .kilo directories and start the kilo agent"

mkdir -p coordinator-workspace/.kilo/agents
mkdir -p coordinator-workspace/.kilo/skills

mkdir -p worker-workspace/.kilo/agents
mkdir -p worker-workspace/.kilo/skills


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
