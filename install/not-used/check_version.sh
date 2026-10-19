docker inspect --format='{{index .Config.Labels "org.opencontainers.image.version"}}' $1
docker image inspect $1 --format '{{json .Config.Labels}}' 


