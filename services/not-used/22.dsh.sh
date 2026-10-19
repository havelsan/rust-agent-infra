
if [ "$RUST_AGENT_INFRA_DIR" = "" ]
then
        echo "RUST_AGENT_INFRA_DIR environment variable not found ! "
        echo "Source the release file in the agent-infra directory !"
        exit 1
fi

cd $RUST_AGENT_INFRA_DEV_TOOLS/deepseek-harness

pnpm dsh web >& $RUST_AGENT_INFRA_LOG_DIR/dsh.log &




