## https://github.com/vllm-project/vllm/releases
## you may also select a release from there and install the image by its version.


sudo docker pull vllm/vllm-openai:v0.28.0
sudo docker run --rm --entrypoint pip vllm/vllm-openai:v0.28.0 show vllm
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
