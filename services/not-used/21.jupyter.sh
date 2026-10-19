
if [ "$RUST_AGENT_INFRA_DIR" = "" ]
then
        echo "RUST_AGENT_INFRA_DIR environment variable not found ! "
        echo "Source the release file in the agent-infra directory !"
        exit 1
fi


DOCKER_NAME=JUPYTER_0

mkdir -p $RUST_AGENT_INFRA_DATA_DIR/jupyter_data
chmod -Rf 777 $RUST_AGENT_INFRA_DATA_DIR/jupyter_data 

sudo docker inspect $DOCKER_NAME &>/dev/null
if [ $? = 0 ]
then
    sudo docker start $DOCKER_NAME  
else
    # DISABLE restart=always
    sudo docker run --name $DOCKER_NAME -p 7777:8888 -v $RUST_AGENT_INFRA_DATA_DIR/jupyter_data/:/home/jovyan/work  --user root -e GRANT_SUDO=yes -e DOCKER_STACKS_JUPYTER_CMD=notebook -d quay.io/jupyter/scipy-notebook:2026-07-28 >& $RUST_AGENT_INFRA_LOG_DIR/jupyter.log &

    # prom/jupyter

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
DOCS : https://jupyter-docker-stacks.readthedocs.io/en/latest/
      

GOTO : 
"
docker logs JUPYTER_0 2>&1|  grep "http://localhost:8888/tree?token=" | tail -1


