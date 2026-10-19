
if [ "$RUST_AGENT_INFRA_DIR" = "" ]
then
        echo "RUST_AGENT_INFRA_DIR environment variable not found ! "
        echo "Source the release file in the agent-infra directory !"
        exit 1
fi


DOCKER_NAME=SEARXNG_0

mkdir -p $RUST_AGENT_INFRA_DATA_DIR/searxng_data/config
chmod -Rf 777 $RUST_AGENT_INFRA_DATA_DIR/searxng_data 

sudo docker inspect $DOCKER_NAME &>/dev/null
if [ $? = 0 ]
then
    sudo docker start $DOCKER_NAME  
else
    # DISABLE restart=always
    sudo docker run --name $DOCKER_NAME -p 8888:8080  -v $RUST_AGENT_INFRA_DATA_DIR/searxng_data:/var/cache/searxng/ -v $RUST_AGENT_INFRA_DATA_DIR/searxng_data/config:/etc/searxng/  -d searxng/searxng:2026.7.19-6da6eee26 >& $RUST_AGENT_INFRA_LOG_DIR/searxng.log &

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
DOCS : https://saerxng.tech/documentation/quickstart/
       https://hub.docker.com/r/saerxng/saerxng
       https://docs.searxng.org/admin/installation-docker.html

SERVICE : http://localhost:8888
"

