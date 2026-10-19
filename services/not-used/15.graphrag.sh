
if [ "$RUST_AGENT_INFRA_DIR" = "" ]
then
        echo "RUST_AGENT_INFRA_DIR environment variable not found ! "
        echo "Source the release file in the agent-infra directory !"
        exit 1
fi


DOCKER_NAME=GRAPHRAG_0

mkdir -p $RUST_AGENT_INFRA_DATA_DIR/graphrag_data/configs
chmod -Rf 777 $RUST_AGENT_INFRA_DATA_DIR/graphrag_data 
cp 15.graphrag.sh.server_config.json $RUST_AGENT_INFRA_DATA_DIR/graphrag_data/configs/server_config.json
echo "RUST_AGENT_INFRA_DATA_DIR=$RUST_AGENT_INFRA_DATA_DIR" > 15.graphrag.sh.env
sudo docker compose -f 15.graphrag.sh.docker-compose.yml --env-file 15.graphrag.sh.env up -d

#
#COMMON_CONFIG="-v $RUST_AGENT_INFRA_DATA_DIR/graphrag_data/configs:/configs -e CONFIG_FILES=/configs/server_config.json -e SERVER_CONFIG=/code/configs/server_config.json -e INIT_EMBED_STORE=false  -e LOGLEVEL=INFO -e USE_CYPHER=true --add-host=host.docker.internal:host-gateway "

#sudo docker inspect $DOCKER_NAME &>/dev/null
#if [ $? = 0 ]
#then
#    sudo docker start ${DOCKER_NAME}_COMMUNITY
#    sleep 1
#    sudo docker start ${DOCKER_NAME}_CHAT_HISTORY
#    sleep 1
#    sudo docker start ${DOCKER_NAME}_ECC
#    sleep 1
#    sudo docker start ${DOCKER_NAME}
#    sleep 1
#    sudo docker start ${DOCKER_NAME}_UI
#else
#    # DISABLE restart=always
#    sudo docker run --name ${DOCKER_NAME}_COMMUNITY -p 14240:14240 $COMMON_CONFIG -d tigergraph/community:4.2.4 >& $RUST_AGENT_INFRA_LOG_DIR/graphrag.commumity.log &
#    sleep 1
#    sudo docker run --name ${DOCKER_NAME}_CHAT_HISTORY -p 6102:8002 $COMMON_CONFIG -d tigergraph/chat-history:2.0.1 >& $RUST_AGENT_INFRA_LOG_DIR/graphrag.chat_history.log &
#    sleep 1
#    sudo docker run --name ${DOCKER_NAME}_ECC -p 6101:8001 $COMMON_CONFIG -d tigergraph/graphrag-ecc:2.0.1 >& $RUST_AGENT_INFRA_LOG_DIR/graphrag.ecc.log &
#    sleep 1
#    sudo docker run --name ${DOCKER_NAME} -p 6100:8000 $COMMON_CONFIG -d tigergraph/graphrag:2.0.1 >& $RUST_AGENT_INFRA_LOG_DIR/graphrag.log &
#    sleep 1
#    sudo docker run --name ${DOCKER_NAME}_UI -p 6103:3000 $COMMON_CONFIG -d tigergraph/graphrag-ui:2.0.1 >& $RUST_AGENT_INFRA_LOG_DIR/graphrag.ui.log &
#    sleep 1
#fi


echo "Checking service status..."
if ! curl -s http://localhost:14240/restpp/version >/dev/null; then
  echo "Starting TigerGraph instance..."
  docker exec tigergraph /home/tigergraph/tigergraph/app/cmd/gadmin start all >/dev/null
  sleep 5
fi

time_out=300
while [[ $time_out -gt 0 ]]; do
  if ! curl -s http://localhost:14240/restpp/version >/dev/null; then
    echo "Waiting for TigerGraph instance to be ready... (${time_out}s remaining)"
    sleep 5
    time_out=$((time_out-5))
  else
    echo "TigerGraph is ready. Starting GraphRAG service..."
    docker compose up -d graphrag >/dev/null
    break
  fi
done

if ! docker ps | grep "tigergraph/graphrag:2.0.1" >/dev/null; then
  echo "Failed to start GraphRAG service."
  echo 'Please double check tigergraph username and password in configs/server_config.json, and re-run `docker compose up -d`'
  echo 'Or check log via `docker logs graphrag` for detailed failure.'
else
  echo "GraphRAG service started successfully."
  echo "Visit http://localhost to access the chatbot."
fi

echo "

https://hub.docker.com/r/tigergraph/graphrag
https://github.com/tigergraph/graphrag#use-tigergraph-docker-based-instance
https://medium.com/@mishakansha.01/my-first-time-building-with-tigergraph-graphrag-7df4b3054c9f
https://raw.githubusercontent.com/tigergraph/graphrag/refs/heads/main/docs/tutorials/setup_graphrag.sh

in $0.server_config.json file, for OPENAI_API_KEY :  Get API KEY from the new-api admin web intraface (http://localhost:3000/keys) , click on the copy icon near the Api Key of API_KEY_0 line.




GO TO : http://localhost:14240

username/password : tigergraph/tigergraph

Test Locally : 
     docker exec -it GRAPHRAG_0_COMMUNITY /bin/bash
     gsql -u tigergraph -p tigergraph
          exit this command interface
     curl -X GET 'http://localhost:9000/echo'

 To delete all docker containers created by this script :
 docker container rm -f graphrag-ui graphrag graphrag-ecc chat-history tigergraph

"

