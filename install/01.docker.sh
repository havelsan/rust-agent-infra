sudo apt-get update
sudo apt install docker.io docker-compose-v2
sudo usermod -aG sudo $USER
sudo usermod -aG docker $USER

echo " 
If you don't want to write 'sudo docker ....' every time you execute the command,

in /etc/sudoers file : 

Change the following line
%sudo ALL=(ALL:ALL) ALL

wiht the following :
%sudo   ALL=(ALL:ALL) NOPASSWD: ALL

"

sleep 10

