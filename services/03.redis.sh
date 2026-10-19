
if [ "$RUST_AGENT_INFRA_DIR" = "" ]
then
        echo "RUST_AGENT_INFRA_DIR environment variable not found ! "
        echo "Source the release file in the rust-agent-infra directory !"
        exit 1
fi


DOCKER_NAME=REDIS_0

mkdir -p $RUST_AGENT_INFRA_DATA_DIR/redis_data

sudo docker inspect $DOCKER_NAME &>/dev/null
if [ $? = 0 ]
then
    sudo docker start  $DOCKER_NAME 
    #sudo docker container rm -f P $DOCKER_NAME
else
    #docker run -d --name  $DOCKER_NAME -p 6379:6379 -v $RUST_AGENT_INFRA_DATA_DIR/redis_data:/data --restart unless-stopped redis redis-server --appendonly yes --requirepass "your_strong_password" >& $RUST_AGENT_INFRA_LOG_DIR/redis.log &
    #disabled restart=unless-stopped
    #
    docker run -d --name  $DOCKER_NAME -p 6379:6379 -v $RUST_AGENT_INFRA_DATA_DIR/redis_data:/data redis:8.10 redis-server --appendonly yes --requirepass "redis_password" >& $RUST_AGENT_INFRA_LOG_DIR/redis.log &
fi

