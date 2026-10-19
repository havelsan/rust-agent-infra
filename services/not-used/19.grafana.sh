
if [ "$RUST_AGENT_INFRA_DIR" = "" ]
then
        echo "RUST_AGENT_INFRA_DIR environment variable not found ! "
        echo "Source the release file in the agent-infra directory !"
        exit 1
fi


DOCKER_NAME=GRAFANA_0

mkdir -p $RUST_AGENT_INFRA_DATA_DIR/grafana_data
chmod -Rf 777 $RUST_AGENT_INFRA_DATA_DIR/grafana_data 

sudo docker inspect $DOCKER_NAME &>/dev/null
if [ $? = 0 ]
then
    sudo docker start $DOCKER_NAME  
else
    # DISABLE restart=always
    sudo docker run --name $DOCKER_NAME -p 13000:3000 -v $RUST_AGENT_INFRA_DATA_DIR/grafana_data/:/var/lib/grafana  -d grafana/grafana:13.0.6 >& $RUST_AGENT_INFRA_LOG_DIR/grafana.log &

    # prom/grafana

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
DOCS : https://grafana.com/docs/grafana/latest/setup-grafana/configure-docker/
      

GOTO : http://localhost:13000
Default credentials : admin/admin

"

