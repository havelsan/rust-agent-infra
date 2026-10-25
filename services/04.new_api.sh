
if [ "$RUST_AGENT_INFRA_DIR" = "" ]
then
        echo "RUST_AGENT_INFRA_DIR environment variable not found ! "
        echo "Source the release file in the rust-agent-infra directory !"
        exit 1
fi


echo
echo
echo "ATTENTION : CLEAN THE HISTORY (CACHE) OF YOUR BROWSER FIREFOX/CHROME BEFORE HEADING TO http://localhost:3000 ''''"
sleep 10
echo
echo

#https://github.com/QuantumNous/new-api

export VLLM_API_KEY="your-custom-local-key"

mkdir -p $RUST_AGENT_INFRA_DATA_DIR/new_api

DOCKER_NAME=NEWAPI_0
sudo docker inspect $DOCKER_NAME &>/dev/null
if [ $? = 0 ]
then
    sudo docker start $DOCKER_NAME 
else

  #sudo docker run -d --name $DOCKER_NAME --network llm-net -p 3000:3000 -v ./data:/data -e TZ=America/New_York calciumion/new-api:latest
  # --restart always
  sudo docker run -d --name $DOCKER_NAME  -p 3000:3000 -v $RUST_AGENT_INFRA_DATA_DIR/new_api:/data -e TZ=$(timedatectl show --property=Timezone --value) -e REDIS_CONN_STRING="redis://:redis_password@host.docker.internal:6379"  -e SQL_DSN="postgresql://pguser:pgpassword@host.docker.internal:5432/pgdb?sslmode=disable" --add-host=host.docker.internal:host-gateway calciumion/new-api:v1.0.0-rc.24 >& $RUST_AGENT_INFRA_LOG_DIR/newapi.log &


  # sudo docker logs NEWAPI_0
  # komutuyla bakinca username/password hatasi cikabilir,
  #
  # psql -h localhost -U pguser -d pgdb
  # password : pgpassword
  # if it does not work :
  # There is a chance that you changed the username/passwords after creating first container, so you have to clean the previous data and reconstruct new container with new user/pass.
  # docker container ls -a | grep POSTGRE_0 , using this commnad determine the container id , and with the command "sudo docker container rm -f <id>"  , stop and delete that container
  # rm -Rf  $RUST_AGENT_INFRA_DATA_DIR/pgdata
  # ./02.postgres.sh 

fi

WAIT_FOR_STARTUP=1

while [ $WAIT_FOR_STARTUP = 1 ]
do
      #sudo docker ps | grep $DOCKER_NAME
      netstat -an | grep tcp | grep 3000
      if [ $? = 0 ]
      then
	      WAIT_FOR_STARTUP=0
      fi
      
      sleep 5
done


echo "$DOCKER_NAME Process is started ..."

nvidia-smi
 
#sudo docker logs $DOCKER_NAME


echo '

For the first-time setup, when you try to go to http://localhost:3000, you are redirected to  http://localhost:3000/setup

In the setup screen :
    Database should already be configured as postgresql, just click next button,
    Create admin account with admin/admin123
    Usage Mode = External Operations
    Click the "Initliaze the System" button.

Login as admin 

Click on the "Console" link found on top menu of the page

Click on the "System Settings" found on the left menu > Billing and Payment > Model Pricing > Press "Add Model" > Model Name = "/local_model" , input price = "1" , then press on the  "save model prices" button.

Click on the "Console" link found on top menu of the page

Click on the "Channels" link found on the left menu.

Click on the "Create Channel" button
    Type = "OpenAI"
    Name = "Qwen3.5-4B-AWQ"
    Base URL = "http://host.docker.internal:8000"
    API Key = "NONE"
    Models = "/local_model"
    --> IMPORTANT :  "/local_model" variable value comes from the --model in the 01.vllm.sh

    Click Save Changes

Click on the "..."  found on the newly created channel
Click on the "Test Connection" button.
Click on the "Test All Models" button.
     After this test , /local_model  should be "success".


Configure API KEY using Console > API Keys > Create API Key button.
     Name = API_KEY_0
     Group = Default
     Quantity = 1
     Unlimited Quota

You will copy the "API KEY" of API_KEY_0  and paste to the OpenWebUI Configuration 

     

'

