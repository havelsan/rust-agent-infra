if [ "$RUST_AGENT_INFRA_DIR" = "" ]
then
	echo "no RUST_AGENT_INFRA_DIR envvironment variable found. Please source the 'release' file found in the parent directory of this script (agent-infra/release)"
	exit 1
fi

echo "Applying $RUST_AGENT_INFRA_DIR/harness to this directory ..."

mkdir -p .kilo

for dir in modes-agents workflows-commands skills-skills
do
	rust_agent_infra_harness=$(echo $dir | cut -d- -f1)
	kilo_harness=$(echo $dir | cut -d- -f2)
	echo "Mapping files in the agent-infra harness directory : $rust_agent_infra_harness TO the  kilo harness directory : $kilo_harness ...." 
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
