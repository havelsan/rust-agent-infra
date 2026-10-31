
if [ "$RUST_AGENT_INFRA_DIR" = "" ]
then
        echo "RUST_AGENT_INFRA_DIR environment variable not found ! "
        echo "Source the release file in the rust-agent-infra directory !"
        exit 1
fi



#https://github.com/QuantumNous/new-api

mkdir -p $RUST_AGENT_INFRA_DATA_DIR/nginx_data
cp ./05.nginx.sh.nginx.conf $RUST_AGENT_INFRA_DATA_DIR/nginx_data/nginx.conf

DOCKER_NAME=NGINX_0
sudo docker inspect $DOCKER_NAME &>/dev/null
if [ $? = 0 ]
then
    sudo docker start $DOCKER_NAME 
else
    sudo docker run -d --name $DOCKER_NAME  -p 4000:80 -v $RUST_AGENT_INFRA_DATA_DIR/nginx_data/nginx.conf:/etc/nginx/conf.d/default.conf --add-host=host.docker.internal:host-gateway nginx:1.30.4 >& $RUST_AGENT_INFRA_LOG_DIR/nginx.log &

fi

WAIT_FOR_STARTUP=1

while [ $WAIT_FOR_STARTUP = 1 ]
do
      #sudo docker ps | grep $DOCKER_NAME
      netstat -an | grep tcp | grep 4000
      if [ $? = 0 ]
      then
	      WAIT_FOR_STARTUP=0
      fi
      
      sleep 5
done


echo "$DOCKER_NAME Process is started ..."

#sudo docker logs $DOCKER_NAME


echo '
http://localhost:4000/


'

