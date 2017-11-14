#!/bin/bash

# variables
IMG_NAME="mjaglan/ubuntuhadoop2017"
HOST_PREFIX="testbed"
NETWORK_NAME=$HOST_PREFIX

# if desired, clean up containers
docker stop $(docker ps -a -q)
docker rm $(docker ps -a -q)

# if desired, clean up images
#docker rmi $(docker images -q)

# total number of slave nodes
N=${1:-3}
rm -f config/slaves
i=1
while [ $i -le $N ]
do
	HADOOP_SLAVE="$HOST_PREFIX"-slave-$i
	echo $HADOOP_SLAVE >> config/slaves
	i=$(( $i + 1 ))
done

# build the Dockerfile
docker build  -t "$IMG_NAME" "$(pwd)"

# Default docker network name is 'bridge', driver is 'bridge', scope is 'local'
# Hadoop multi-node cluster does NOT work on default network.
# Create a new network with any name, and keep 'bridge' driver for 'local' scope.
NET_QUERY=$(docker network ls | grep -i $NETWORK_NAME)
if [ -z "$NET_QUERY" ]; then
	docker network create --driver=bridge $NETWORK_NAME
fi

# start hadoop slave container(s)
i=1
while [ $i -le $N ]
do
	HADOOP_SLAVE="$HOST_PREFIX"-slave-$i
	docker run --name $HADOOP_SLAVE -h $HADOOP_SLAVE --net=$NETWORK_NAME -itd "$IMG_NAME"
	i=$(( $i + 1 ))
done

# start hadoop master container
: '
LINK: https://stackoverflow.com/a/35901232
Daemon                   Default Port  Configuration Parameter
-----------------------  ------------ ----------------------------------
Master                   8080         spark.master.ui.port
ResourceManager          8088         yarn.resourcemanager.webapp.address
Namenode                 50070        dfs.http.address
Secondarynamenode        50090        dfs.secondary.http.address
'
HADOOP_MASTER="$HOST_PREFIX"-master
docker run --name $HADOOP_MASTER -h $HADOOP_MASTER --net=$NETWORK_NAME \
		-p  8088:8088  -p 50070:50070 -p 50090:50090 \
		-p  8080:8080 \
		-itd "$IMG_NAME"

# see active docker containers
docker ps

# start multi-node cluster
docker exec -it $HADOOP_MASTER "/usr/local/hadoop/spark-services.sh"

# attach to hadoop master container
docker attach $HADOOP_MASTER
