
if [ "$RUST_AGENT_INFRA_DIR" = "" ]
then
        echo "RUST_AGENT_INFRA_DIR environment variable not found ! "
        echo "Source the release file in the agent-infra directory !"
        exit 1
fi


DOCKER_NAME=N8N_0

mkdir -p $RUST_AGENT_INFRA_DATA_DIR/n8n_data

sudo docker inspect $DOCKER_NAME &>/dev/null
if [ $? = 0 ]
then
    sudo docker start $DOCKER_NAME  
else
    # DISABLE restart=always
    # SQL_DSN="postgresql://pguser:pgpassword@host.docker.internal:5432/pgdb?sslmode=disable" --add-host=host.docker.internal:host-gateway calciumion/new-api:latest

    sudo docker run --name $DOCKER_NAME --add-host=host.docker.internal:host-gateway -p 5678:5678 -e DB_TYPE=postgresdb -e DB_POSTGRESDB_DATABASE=pgdb -e DB_POSTGRESDB_HOST=host.docker.internal -e DB_POSTGRESDB_PORT=5432 -e DB_POSTGRESDB_USER=pguser -e DB_POSTGRESDB_SCHEMA=n8n_schema  -e DB_POSTGRESDB_PASSWORD=pgpassword  -v $RUST_AGENT_INFRA_DATA_DIR/n8n_data:/home/node/.n8n -d docker.n8n.io/n8nio/n8n:2.30.7 >& $RUST_AGENT_INFRA_LOG_DIR/n8n.log &

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


echo "n8n : node config : AI > Open AI > Message a model.      http://host.docker.internal:3000/v1  , apikey can be copied from http://localhost:3000/keys"
