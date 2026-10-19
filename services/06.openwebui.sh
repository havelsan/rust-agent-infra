

if [ "$RUST_AGENT_INFRA_DIR" = "" ]
then
        echo "RUST_AGENT_INFRA_DIR environment variable not found ! "
        echo "Source the release file in the rust-agent-infra directory !"
        exit 1
fi


DOCKER_NAME=OPEN_WEB_UI_0

mkdir -p $RUST_AGENT_INFRA_DATA_DIR/open_web_ui_data

sudo docker inspect $DOCKER_NAME &>/dev/null
if [ $? = 0 ]
then
    sudo docker start $DOCKER_NAME
    #sudo docker container rm -f $DOCKER_NAME
else
    #docker run -d -p 3000:8080 --add-host=host.docker.internal:host-gateway -v $RUST_AGENT_INFRA_DATA_DIR/open_web_ui_data:/app/backend/data --name $DOCKER_NAME --restart always ghcr.io/open-webui/open-webui:main
    #docker run -d -p 8080:8080 --add-host=host.docker.internal:host-gateway -e OPENAI_API_BASE_URL=http://host.docker.internal:8000/v1 -v $RUST_AGENT_INFRA_DATA_DIR/open_web_ui_data:/app/backend/data --name $DOCKER_NAME --restart always ghcr.io/open-webui/open-webui:main
    ## connect to new_api, not vllm. also disable restart always
    sudo docker run -d -p 8080:8080 --add-host=host.docker.internal:host-gateway -e OPENAI_API_BASE_URL=http://host.docker.internal:3000/v1 -v $RUST_AGENT_INFRA_DATA_DIR/open_web_ui_data:/app/backend/data --name $DOCKER_NAME  ghcr.io/open-webui/open-webui:v0.11.0



fi


echo '

For the first-time setup, Click on the "Get Started" button found on the bottom of the page.
    Name = Mehmet Pekmezci
    Email = mehmet.pekmezci.32@gmail.com
    Password = admin123456

    Then Click "Create Admin Account"


To configure new-api in the open web ui, click on the "user icon" found in the top-most and the right-most of the page.

Click on Admin Panel

Click on Settings on the top menu.

Click on Connections link on the left menu.

In the "Manage OpenAI API connections" section in the page, there is an entry, and a "settings" icon in the right-most of that line, click on that icon.
       URL=http://host.docker.internal:3000/v1
           Get API KEY from the new-api admin web intraface (http://localhost:3000/keys) , click on the copy icon near the Api Key of API_KEY_0 line.
       Auth = Bearer, <paste the api key you copied from new-api>
       Save

API_KEY = sk-EoJCdSt5ZfEzQqny7AlzEfeyNiwRpT96bgrWnwKWGCSNPOgQ

NOTE: if you get this error : "auto" tool choice requires --enable-auto-tool-choice and --tool-call-parser to be set 
      then you should moodify 01.vllm.sh and start the docker image using "--enable-auto-tool-choice --tool-call-parser hermes" for qwen, "--enable-auto-tool-choice --tool-call-parser llama3" for ollama.





'

