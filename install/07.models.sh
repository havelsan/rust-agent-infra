#
if [ "$RUST_AGENT_INFRA_DIR" = "" ]
then
        echo "RUST_AGENT_INFRA_DIR environment variable not found ! "
        echo "Source the release file in the agent-infra directory !"
        exit 1
fi

pip3 install -U "huggingface_hub[cli]" --break-system-packages

mkdir -p $RUST_AGENT_INFRA_MODELS_DIR/$RUST_AGENT_INFRA_MODEL

if [ ! -f $RUST_AGENT_INFRA_MODELS_DIR/$RUST_AGENT_INFRA_MODEL/*.safetensors ]
then
    hf download "$RUST_AGENT_INFRA_MODEL" --local-dir $RUST_AGENT_INFRA_MODELS_DIR/$RUST_AGENT_INFRA_MODEL
fi

#if [ "$RUST_AGENT_INFRA_MODEL_TOKENIZER" != "" -a ! -f $RUST_AGENT_INFRA_MODELS_DIR/$RUST_AGENT_INFRA_MODEL/tokenizer/config.json ]
#then
#   
#   mkdir -p $RUST_AGENT_INFRA_MODELS_DIR/$RUST_AGENT_INFRA_MODEL/tokenizer
#   hf download "$RUST_AGENT_INFRA_MODEL_TOKENIZER" config.json --local-dir $RUST_AGENT_INFRA_MODELS_DIR/$RUST_AGENT_INFRA_MODEL/
#   hf download "$RUST_AGENT_INFRA_MODEL_TOKENIZER" tokenizer.json --local-dir $RUST_AGENT_INFRA_MODELS_DIR/$RUST_AGENT_INFRA_MODEL/tokenizer
#   hf download "$RUST_AGENT_INFRA_MODEL_TOKENIZER" tokenizer_config.json --local-dir $RUST_AGENT_INFRA_MODELS_DIR/$RUST_AGENT_INFRA_MODEL/tokenizer
##    hf download "$RUST_AGENT_INFRA_MODEL_HF_CONFIGS" generation_config.json --local-dir $RUST_AGENT_INFRA_MODELS_DIR/HF-CONFIG-$RUST_AGENT_INFRA_MODEL
#fi

echo
echo
echo ls $RUST_AGENT_INFRA_MODELS_DIR/$RUST_AGENT_INFRA_MODEL
ls $RUST_AGENT_INFRA_MODELS_DIR/$RUST_AGENT_INFRA_MODEL


