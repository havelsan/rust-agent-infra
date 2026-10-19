
if [ "$RUST_AGENT_INFRA_DIR" = "" ]
then
        echo "RUST_AGENT_INFRA_DIR environment variable not found ! "
        echo "Source the release file in the agent-infra directory !"
        exit 1
fi


DOCKER_NAME=NEO4J_0

mkdir -p $RUST_AGENT_INFRA_DATA_DIR/neo4j_data
mkdir -p $RUST_AGENT_INFRA_LOG_DIR/neo4j_logs
chmod -Rf 777 $RUST_AGENT_INFRA_DATA_DIR/neo4j_data $RUST_AGENT_INFRA_LOG_DIR/neo4j_logs

sudo docker inspect $DOCKER_NAME &>/dev/null
if [ $? = 0 ]
then
    sudo docker start $DOCKER_NAME  
else
    # DISABLE restart=always
    sudo docker run --name $DOCKER_NAME   --add-host=host.docker.internal:host-gateway  -e NEO4J_AUTH=neo4j/secretpassword  -p 7474:7474 -p 7687:7687 -v $RUST_AGENT_INFRA_DATA_DIR/neo4j_data:/data -v $RUST_AGENT_INFRA_LOG_DIR/neo4j_logs:/logs -d neo4j:5.26.29-ubi10 >& $RUST_AGENT_INFRA_LOG_DIR/neo4j.log &
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

echo "Usage :
 1. Open your web browser. (e.g. Firefox-153.0.3)
 2. Navigate to http://localhost:7474 to launch the database GUI.
 3. Log in parameters :
    3.1. Protocol = neo4j://
    3.2. Connection URL = localhost:7687
    3.3. We suppose NEO4J_AUTH=neo4j/secretpassword
    3.3.1. Database User = neo4j (first parth of NEO4J_AUTH)
    3.3.2. Password = secretpassword (second parth of NEO4J_AUTH)
"

