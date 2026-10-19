## https://github.com/vllm-project/vllm/releases
## you may also select a release from there and install the image by its version.


sudo docker pull calciumion/new-api:v1.0.0-rc.24
echo
echo
echo
echo "#### DOCKER IMAGES LIST:"
echo
sudo docker image list


echo
echo
echo
echo "#### DOCKER CONTAINERS LIST:"
echo
sudo docker container list -a

# you may also delete using :
# sudo docker image rm "vllm/vllm-openai:latest"
#
