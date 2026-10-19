#!/bin/bash

echo "If you have corrupted images 
      run 'docker system prune'
      before running this script !
"
sleep 5

if [ "$RUST_AGENT_INFRA_DIR" = "" ]
then
	echo "RUST_AGENT_INFRA_DIR environment variable not found ! "
	echo "Source the release file in the rust-agent-infra directory !"
        exit 1
fi

groups| grep ' sudo '>/dev/null
if [ $? != 0 ]
then
	echo "execute the following command then re-run this script:"
	echo "sudo usermod -aG sudo $USER"
        exit 1
fi

sudo grep '^%sudo' /etc/sudoers| grep NOPASSWD>/dev/null
if [ $? != 0 ]
then
       echo "replace this line:"
       echo "%%sudo	ALL=(ALL:ALL) ALL"
       echo "with the following line in /etc/sudoers then re-run this script :"
       echo "%sudo	ALL=(ALL:ALL) NOPASSWD: ALL"
       exit 1
fi

cd $RUST_AGENT_INFRA_DIR/install


for installation_script in $(ls *.sh| grep -v _ | grep [0-9] | grep -v 00)
do
   echo
   echo
   echo "STARTED: $installation_script"
   echo
   echo
   bash $installation_script
   echo
   echo
   echo "FINISHED:  $installation_script"
   echo
   echo
done


echo "docker image inspect <image_name_or_id> --format '{{json .Config.Labels}}'"

