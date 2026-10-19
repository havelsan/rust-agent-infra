

if [ -f $RUST_AGENT_INFRA_DEV_TOOLS/claude/*claude* ]
then
	echo "You already have  $RUST_AGENT_INFRA_DEV_TOOLS/claude/*claude* "
	exit 0
fi

mkdir -p $RUST_AGENT_INFRA_DEV_TOOLS/claude

cd $RUST_AGENT_INFRA_DEV_TOOLS/claude

wget https://claude.ai/install.sh 
bash ./install.sh





