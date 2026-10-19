
if [ "$RUST_AGENT_INFRA_DIR" = "" ]
then
        echo "RUST_AGENT_INFRA_DIR environment variable not found ! "
        echo "Source the release file in the agent-infra directory !"
        exit 1
fi


DOCKER_NAME=FUSEKI_0

mkdir -p $RUST_AGENT_INFRA_DATA_DIR/fuseki_data
chmod -Rf 777 $RUST_AGENT_INFRA_DATA_DIR/fuseki_data

sudo docker inspect $DOCKER_NAME &>/dev/null
if [ $? = 0 ]
then
    sudo docker start $DOCKER_NAME  
else

    # DISABLE restart=always
    sudo docker run --name $DOCKER_NAME  -e ADMIN_PASSWORD=my_password_0 -e TDB=2 -p 3030:3030 -v $RUST_AGENT_INFRA_DATA_DIR/fuseki_data:/fuseki/databases -d stain/jena-fuseki:5.1.0 >& $RUST_AGENT_INFRA_LOG_DIR/fuseki.log &


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


echo "https://hub.docker.com/r/stain/jena-fuseki"

echo "docker run --volumes-from fuseki-data -v /home/stain/ops/chembl19:/staging stain/jena-fuseki ./load.sh chembl19 cco.ttl.gz void.ttl.gz"
