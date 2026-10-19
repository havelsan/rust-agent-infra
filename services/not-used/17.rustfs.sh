
if [ "$RUST_AGENT_INFRA_DIR" = "" ]
then
        echo "RUST_AGENT_INFRA_DIR environment variable not found ! "
        echo "Source the release file in the agent-infra directory !"
        exit 1
fi


DOCKER_NAME=RUSTFS_0

mkdir -p $RUST_AGENT_INFRA_DATA_DIR/rustfs_data/logs
chmod -Rf 777 $RUST_AGENT_INFRA_DATA_DIR/rustfs_data 

sudo docker inspect $DOCKER_NAME &>/dev/null
if [ $? = 0 ]
then
    sudo docker start $DOCKER_NAME  
else
    # DISABLE restart=always
    sudo docker run --name $DOCKER_NAME -p 9000:9000 -p 9001:9001 -v $RUST_AGENT_INFRA_DATA_DIR/rustfs_data:/data -v $RUST_AGENT_INFRA_DATA_DIR/rustfs_data/logs:/logs  -d rustfs/rustfs:1.0.0-rc.1 >& $RUST_AGENT_INFRA_LOG_DIR/rustfs.log &

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
DOCS : https://docs.rustfs.com/en/installation/container
       https://github.com/rustfs/rustfs

GOTO : http://localhost:9001/rustfs/console/auth/login/
Default credentials: rustfsadmin / rustfsadmin

"

