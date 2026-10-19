#!/bin/bash

if [ "$RUST_AGENT_INFRA_DIR" = "" ]
then
	echo "RUST_AGENT_INFRA_DIR environment variable not found ! "
	echo "Source the release file in the agent-infra directory !"
        exit 1
fi


cd $RUST_AGENT_INFRA_DIR/services

mkdir -p $RUST_AGENT_INFRA_LOG_DIR


for start_script in $(ls *.sh| grep [0-9] | grep -v 00)
do
   echo
   echo
   echo "RUNNING: $start_script"
   echo
   echo
   bash $start_script
   echo "Waiting 5 seconds to let the $start_script start ..."
   sleep 5
   
done


## docker exec -it <conainer_name or id> /bin/bash
## example : docker exec -it WEB_PROTEGE_0 /bin/bash
## 



