
if [ "$RUST_AGENT_INFRA_DIR" = "" ]
then
        echo "RUST_AGENT_INFRA_DIR environment variable not found ! "
        echo "Source the release file in the agent-infra directory !"
        exit 1
fi


DOCKER_NAME=QDRANT_0

mkdir -p $RUST_AGENT_INFRA_DATA_DIR/qdrant_data
chmod -Rf 777 $RUST_AGENT_INFRA_DATA_DIR/qdrant_data 

sudo docker inspect $DOCKER_NAME &>/dev/null
if [ $? = 0 ]
then
    sudo docker start $DOCKER_NAME  
else
    # DISABLE restart=always
    sudo docker run --name $DOCKER_NAME -p 6333:6333 -p 6334:6334  -v $RUST_AGENT_INFRA_DATA_DIR/qdrant_data:/qdrant/storage:z -d qdrant/qdrant:v1.18.3 >& $RUST_AGENT_INFRA_LOG_DIR/qdrant.log &

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

echo "
This is a vectordb

DOCS : https://qdrant.tech/documentation/quickstart/
       https://hub.docker.com/r/qdrant/qdrant

SERVICE : http://localhost:6333
          http://localhost:6333/dashboard 
"

