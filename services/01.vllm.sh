

if [ "$RUST_AGENT_INFRA_DIR" = "" ]
then
        echo "RUST_AGENT_INFRA_DIR environment variable not found ! "
        echo "Source the release file in the agent-infra directory !"
        exit 1
fi

#sudo docker run --rm --entrypoint pip vllm/vllm-openai show vllm

DOCKER_NAME=VLLM_0
sudo docker inspect $DOCKER_NAME &>/dev/null
if [ $? = 0 ]
then
    sudo docker start $DOCKER_NAME 
else

#  --model /local_model/$RUST_AGENT_INFRA_SUB_MODEL \
#  --tokenizer /local_model/tokenizer \
#  --hf-config-path /local_model/config.json \
#  --gpu-memory-utilization 0.95 \
#  --enable-auto-tool-choice --tool-call-parser $RUST_AGENT_INFRA_MODEL_TOOL_CALL_PARSER \
#  --reasoning-parser $RUST_AGENT_INFRA_MODEL_REASONING_PARSER \
#  --dtype float16 \
#  --kv-cache-dtype fp8 \
#  --max-model-len 16000" 

##  --cpu-offload-gb 2 \
##  --kv-offloading-size 2 \
## --language-model-only  _> image and video modes are off
## kv-cache-memory=519837389 == 500MB
#--env PYTORCH_CUDA_ALLOC_CONF=expandable_segments:True
##  --kv-cache-memory-bytes 30M \
#  --max-num-batched-tokens=10000
COMMAND="sudo docker run --name $DOCKER_NAME --runtime nvidia --gpus all \
	  -v $RUST_AGENT_INFRA_MODELS_DIR/$RUST_AGENT_INFRA_MODEL:/local_model \
  -p 8000:8000 \
  --ipc=host \
  --env "HF_HUB_OFFLINE=1" \
  --env "TRANSFORMERS_OFFLINE=1" \
  --env PYTORCH_CUDA_ALLOC_CONF=expandable_segments:True \
  vllm/vllm-openai:v0.28.0 \
  --model /local_model \
  --gpu-memory-utilization 0.98 \
  --language-model-only \
  --dtype float16 \
  --enable-auto-tool-choice --tool-call-parser $RUST_AGENT_INFRA_MODEL_TOOL_CALL_PARSER \
  --reasoning-parser $RUST_AGENT_INFRA_MODEL_REASONING_PARSER \
  --kv-cache-dtype fp8 \
  --enforce-eager \
  --max-num-seqs=4 \
  --kv-cache-memory-bytes 650M \
  --max-model-len 32000"


## --kv-cache-memory=519837389 == 500MB
  ## --max-model-len 32000 : context len is 32K
##  --dtype float16 
##  --kv-cache-dtype fp8 
##  --quantization fp8, --quantization bnb, or --quantization awq 
#  --restart=always 

echo $COMMAND
bash -c "$COMMAND" >& $RUST_AGENT_INFRA_LOG_DIR/vllm.log &


fi


WAIT_FOR_STARTUP=1

while [ $WAIT_FOR_STARTUP = 1 ]
do
      sudo docker ps | grep $DOCKER_NAME
      if [ $? = 0 ]
      then
	      WAIT_FOR_STARTUP=0
      fi
      
      sleep 5
done


echo "$DOCKER_NAME Process is started ..."

nvidia-smi
 
#sudo docker logs $DOCKER_NAME

