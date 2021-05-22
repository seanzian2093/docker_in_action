# ch6 networking

#1 Memory limit
## use --memory or -m flog to set up limit - int + unit, unit could be b k m g
## works for both docker container run or docker container create 
docker container run -d --name ch6_mariadb \
    --memory 256m \
    --cpu-shares 1024 \
    --cap-drop net_raw \
    -e MYSQL_ROOT_PASSWORD=test \
    mariadb:latest

## use docker stats to check memory usage by containers
docker stats

#2 CPU limit

## use --cpu-shares flog to set up cpu process limit - int
## works for both docker container run or docker container create 
## with ch6_mariadb and ch6_workpress runing at same time, ch6_mariadb will get 1024/(1024+512) portion of cpu, ch6_workpress 512/(1024+512)
## a container or its process may use more than those limit when other container or process is idle
docker container run -d --name ch6_wordpress \
    --memory 512m \
    --cpu-shares 512 \
    --cap-drop net_raw \
    --link ch6_mariadb:mysql \
    -e WORDPRESS_DB_PASSWORD=test \
    wordpress:5.0.0-php7.2-apache


## use --cpus flag to let a process consume max number of cores
## this is enforced by Linux Completely Fair Scheduler, a.k.a CFS.
## refreshed every 100ms by default
docker container run -d --name ch6_wordpress \
    --memory 512m \
    --cpus 0.75 \
    --cap-drop net_raw \
    --link ch6_mariadb:mysql \
    -e WORDPRESS_DB_PASSWORD=test \
    wordpress:5.0.0-php7.2-apache


## use --cpuset-cpus to restrict container process run on certain cpu core, i.e no context change which is expensive
docker container run -d \
    --cpuset-cpus 0 \
    --name ch6_stresser \
    dockerinaction/ch6_stresser
## start a container to check cpu load
docker container run -it --rm dockerinaction/ch6_htop


## use --device flag to mount a device from host to container
docker container run -it --rm \
    --device /dev/video0:/dev/video0 \
    ubuntu:16.04 ls -al /dev


# 6.2 sharing memory between processes
## interprocess communication, a.k.a IPC
## docker creates a unique IPC namespace for each container to prevent process in one container from accessing memory in another container or host.
docker container run -d -u nobody \
    --name ch6_ipc_producer \
    --ipc shareable \
    dockerinaction/ch6_ipc -producer

docker container run -d -u nobody \
    --name ch6_ipc_consumer \
    --ipc shareable \
    dockerinaction/ch6_ipc -consumer

## check logs - producer produced some message; but consumer does not have access to them because their IPC namespace are separated
docker logs ch6_ipc_producer 
docker logs ch6_ipc_consumer

## restart a consumer container with joining namespaces in --ipc flag; use --ips=host to share with host
docker container run -d -u nobody \
    --name ch6_ipc_consumer \
    --ipc container:ch6_ipc_producer \
    dockerinaction/ch6_ipc -consumer

## check again
docker logs ch6_ipc_consumer


# 6.3 User
## by default, docker starts a container as the use specified in meta, whic is often the root
## any process running as a user has same permission, i.e. inherit

## check default user defined in meta data; if blank, it is root
docker image inspect busybox:1.29
docker image inspect --format "{{.Config.User}}" busybox:1.29

## use --user or -u flag to run as a specific user which has be to existing already in that image
## username is resolved by UID in passwd file
docker container run --rm \
    --user nobody \
    busybox:latest id

## so we could use UID:GID pair directly
docker container run --rm \
    --user 10000:20000 \
    busybox:latest id

# 6.3.2 users and volumes
## users inside containers share the same use ID space with those in host.

echo "e=mc^2" > garbage
chmod 600 garbage
sudo chown root garbage
docker container run --rm \
    -v "$(pwd)"/garbage:/test/garbage \
    -u nobody \
    ubuntu:18.04 cat /test/garbage

# 6.3 Linux User namespace and UID remapping

## LInux usr namespace, a.k.a USR maps users in one namespace to users in another
## By defautd, Docke does not use USR, i.e. a container running as a UID(number not name) same as a UID in host will have same host filesystem permissions as that user
## This poses a problem when volumes share file between containers or with host.

## when a user namespace is enabled for a container, UID in container are mapped to a range of unprevilleged UID in host.
## by subuid and subgid for linux host and by userns-remap option for Docker daemon


# 6.4 adjusting OS feature access with capabilities

## use --cap-drop flag on docker container run or create to remove capability
docker container run --rm \
    -u nobody \
    ubuntu:16.04 \
    /bin/bash -c "capsh --print | grep net_raw"

docker container run --rm \
    -u nobody \
    --cap-drop net_raw \
    ubuntu:16.04 \
    /bin/bash -c "capsh --print | grep net_raw"

## use --cap-add flag on docker container run or create to add apability
docker container run --rm \
    -u nobody \
    --cap-add sys_admin \
    ubuntu:16.04 \
    /bin/bash -c "capsh --print | grep sys_admin"

## use .HostConfig.CapAdd .HostConfig.CapDrop to find info in container meta data
docker container run \
    --name add_sys_admin \
    -u nobody \
    --cap-add sys_admin \
    ubuntu:16.04 \
    /bin/bash -c "capsh --print | grep sys_admin"


# 6.5 Run container with full privilege

## use --privileged flog to docker container run or create
## Privileged containers maintain their filesystem and network isolation
## But have full access to shared memory and devices and possess full system capabilities.