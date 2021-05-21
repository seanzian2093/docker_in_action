#! /bin/bash

# 4.3 in-memory storage
docker run --rm \
    --mount type=tmpfs,dst=/tmp,tmpfs-size=16k,tmpfs-mode=1770 \
    --entrypoint mount \
    alpine:latest -v
## one of the entries is - 
## indicating: a tmpfs device is mounted to /tmp, it is a tmpfs file system, read and write capable,
## suid bits will be ignored on all files in this folder/tree
## no files in this tree will be interpreted as special device
## no files in this tree will be executable
## file access times will  be udpated if they are older than the current modify or change time
## size limit = 16k, 1770 mean not writable to other in-container users; 1777 by default, means world-writable
tmpfs on /tmp type tmpfs (rw,nosuid,nodev,noexec,relatime,size=16k,mode=1770)

# 4.4 volume
## a volume is not associated with any containers, just a named bit of disk that accessible by containers.
## create a volume - add a label of key-value pair, facilitating managing and cleaning up
docker volume create \
    --driver local \
    --label example=location \
    location-example

## list/remove/remove all unused volume
docker volume ls
docker volume rm
docker volume prune

## check it out - with json, will print JSON style string, otherwise string literal by Go.
docker volume inspect \
    --format "{{json .Mountpoint}}" \
    location-example

# 4.4.2 Using volume with NoSQL database
## create a volume for cassandra
docker volume create \
    --driver local \
    --label example=cassandra \
    cass-shared

## start a cassandra container
docker run -d \
    --volume cass-shared:/var/lib/cassandra/data \
    --name cass1 \
    cassandra:2.2
## run a cassandra client tool and link the cass1 as cass
docker run -it --rm \
    --link cass1:cass \
    cassandra:2.2 cqlsh cass

## within cqlsh
select * from system.schema_keyspaces where keyspace_name = 'docker_hello_world';

create keyspace docker_hello_world
with replication = {
    'class': 'SimpleStrategy',
    'replication_factor': 1
};

quit

## start another cassandra container and check the data persisted by volume
docker run -d \
    --volume cass-shared:/var/lib/cassandra/data \
    --name cass2 \
    cassandra:2.2
## run a cassandra client tool and link the cass1 as cass
docker run -it --rm \
    --link cass2:cass \
    cassandra:2.2 cqlsh cass

## remove all containers and volumes
docker rm -vf $(docker ps -a -q)
docker volume rm -f $(docker volume ls -q)
# or let docker determine it is a container or a volume and act accordingly
docker rm -fv cass2 cass-shared

# 4.5 shared mount points and sharing files

## Bind mount approach

## both the writer and reader container need to agree on log_src, they depend on it
LOG_SRC=ch4_bind_mnt/web-logs-example
mkdir -p ${LOG_SRC}
echo "$(pwd)/${LOG_SRC}"

## start a container that writes to the log src
docker run --name plath -d \
    --mount type=bind,src="$(pwd)/${LOG_SRC}",dst=/data \
    dockerinaction/ch4_writer_a

## start a container that reads from the log src
docker run --rm \
    --mount type=bind,src="$(pwd)/${LOG_SRC}",dst=/data \
    alpine:latest \
    head /data/logA

## check log src on host
cat ${LOG_SRC}/logA
docker rm -f plath

## Volume mount approach
docker volume create --driver local logging-example

## start a container that writes to the log src
docker run --name plath -d \
    --mount type=volume,src=logging-example,dst=/data \
    dockerinaction/ch4_writer_a

## start a container that reads from the log src
docker run --rm \
    --mount type=volume,src=logging-example,dst=/data \
    alpine:latest \
    head /data/logA

## check log src on host
## not working on wsl, visit file://wsl%24/docker-desktop-data/version-pack-data/community/docker/volumes/logging-example/_data/
cat "$(docker volume inspect --format "{{json .Mountpoint}}" logging-example)"/logA
docker stop plath


## 4.5.1 anonymous volumes and volumes-from flag
## with no src= provided, a unique and random name will be assigned
docker run --name fowler \
    --mount type=volume,dst=/library/PoEAA \
    --mount type=bind,src=/tmp,dst=/library/DSL \
    alpine:latest \
    echo "Fowler collection created."

docker run --name knuth \
    --mount type=volume,dst=/library/TAoCP.vol1 \
    --mount type=volume,dst=/library/TAoCP.vol2 \
    --mount type=volume,dst=/library/TAoCP.vol3 \
    --mount type=volume,dst=/library/TAoCP.vol4.a \
    alpine:latest \
    echo "Knuth collection created."

## copy volumes directly
docker run --name reader \
    --volumes-from fowler \
    --volumes-from knuth \
    alpine:latest ls -l /library

## copy volumes transitively
docker run --rm \
    --volumes-from reader \
    alpine:latest ls -l /library

docker inspect --format "{{json .Mounts}}" reader

## 3 situations that volumes-from does not work
## change in the src location, change in the permission and source conflict

## an example of source conflict - two container with a volume mounted to same point inthe filesystem
docker run --name chomsky \
    --volume /library/ss \
    alpine:latest \
    echo "Chomsky collection created."

docker run --name lamport \
    --volume /library/ss \
    alpine:latest \
    echo "Lamport collection created."

## two volumes-from flags but only one volume in that container.
docker run --name student \
    --volumes-from chomsky \
    --volumes-from lamport \
    alpine:latest ls -l /library

docker inspect --format "{{json .Mounts}}" student

## remove volume
docker volume remove logging-example
## specify certain volume to remove by providing label 
docker volume prune --filter example=cassandra -f