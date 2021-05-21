# ch5 networking

# 5.1 Intro
# docker treats network as first class entities, i.e. own life cycle, not bound to any other objects.
# docker network subcommand defines and manages networking.

# by default docker includes 3 networks
## bridge - provided by bridge driver, provides intercontainer connectivity for all containers running on the same machine.
## maintains compatibilty with legacy Docker and not recommended to use it since it can not take advantage of new features, e.g load balancing.

## host - provided by host driver, instructs docker not to create any special networking namespaces or resources for attached containers.
## containers on the host network interact with host's network stack like uncontained process.

## none - provided by null driver, containers attached to none will have no connectivity outside themselves.
docker network ls
# NETWORK ID     NAME      DRIVER    SCOPE
# f0a490d42dc7   bridge    bridge    local
# 13218ad6e4e5   host      host      local
# de5f796f8563   none      null      local

## scope
## local - network is constrained to the machine where it exists
## global - should be created on every node in cluster but not route between them
## swarm - seamlessly spans all of the hosts which participat in a Docker swarm, i.e. multi-host or cluster-wide

# 5.2 bridge network
## subnet - ipv4 is octet of 4 parts, each of which is 8bit
## subnet 10.0.42.0/24 means first 24bit is pretected, not available so subnet range is 2**8, 10.0.42.0 - 10.0.42.255
## ip-range 10.0.42.128/25 means first 25bit is pretected, not available so subnet range is 2**7, 10.0.42.128 - 10.0.42.255
docker network create \
    --driver bridge \
    --label project=dockerinaction \
    --label chapter=5 \
    --attachable \
    --scope local \
    --subnet 10.0.42.0/24 \
    --ip-range 10.0.42.128/25 \
    user-network

## explore network
docker run -it \
    --network user-network \
    --name network-explorer \
    alpine:latest sh
## within container run
ip -f inet -4 -o addr
## those are all loopback, i.e. localhost
# 1: lo    inet 127.0.0.1/8 scope host lo\       valid_lft forever preferred_lft forever
# 45: eth0    inet 10.0.42.129/24 brd 10.0.42.255 scope global eth0\       valid_lft forever preferred_lft forever

## create another network
docker network create \
    --driver bridge \
    --label project=dockerinaction \
    --label chapter=5 \
    --attachable \
    --scope local \
    --subnet 10.0.43.0/24 \
    --ip-range 10.0.43.128/25 \
    user-network2

## connect running container to new created network 
docker network connect \
    user-network2 \
    network-explorer

# within container run
apk update && apk add nmap
nmap -sn 10.0.42.* -sn 10.0.43.* -oG /dev/stdout | grep Status

## reattach container to terminal
docker attach network-explorer

## create another container
docker run -d \
    --name lighthouse \
    --network user-network2 \
    alpine:latest sleep 1d

# within container run - lighthouse is found
nmap -sn 10.0.42.* -sn 10.0.43.* -oG /dev/stdout | grep Status
# Host: 10.0.42.128 ()    Status: Up
# Host: 10.0.42.129 (918deea17dc1)        Status: Up
# Host: 10.0.43.128 ()    Status: Up
# Host: 10.0.43.130 (lighthouse.user-network2)    Status: Up
# Host: 10.0.43.129 (918deea17dc1)        Status: Up

docker network rm -f $(docker network ls -q)

# 5.3 special network - host and none
docker run --rm \
    --network host \
    alpine:latest ip -o addr
docker run --rm \
    --network none \
    alpine:latest ip -o addr

# 5.4 port publishing

## forward a random host port to 8080 in container
docker run --rm \
    -p 8080 \
    alpine:latest echo "forward ephemeral TCP -> container TCP 8080"

docker run --rm \
    -p 8088:8080/udp \
    alpine:latest echo "host udp 8088-> container TCP 8080"

docker run --rm \
    -p 127.0.0.1:8080:8080/tcp \
    -p 127.0.0.1:3000:8080/tcp \
    alpine:latest echo "host multiple TCP ports from localhost"

## docker port sumcommand to see port forwarding
docker run -d -p 8080 --name listener alpine:latest sleep 300
docker port listener
# 8080/tcp -> 0.0.0.0:56372

## multiple forwarding
docker run -d \
    -p 8080 \
    -p 3000 \
    -p 6000 \
    --name multi-listener \
    alpine:latest sleep 300
## to see which port in host in forward to 3000 in container
docker port multi-listener 3000

# 5.5.2 DSN configuration

## --hostname flag to docker run maps provided hostname to container's bridge IP address.
docker run --rm \
    --hostname barker \
    alpine:latest nslookup barker
## not sure why the error
# Server:         192.168.65.5
# Address:        192.168.65.5:53

# ** server can't find barker: NXDOMAIN

# ** server can't find barker: NXDOMAIN

## --dns flag to add a dns for container to use
docker run --rm \
    --dns 8.8.8.8 \
    alpine:latest nslookup docker.com 

## --dns-search flag to specify a dns search domain for container to use
docker run --rm \
    --dns-search docker.com \
    alpine:latest nslookup hub

## both --dsn and --dsn-search work by manipulating /etc/resolv.conf
## both can be used multiple time to add more configs
## set for container only when created,
docker run --rm \
    --dns-search docker.com \
    --dns 8.8.8.8 \
    --add-host test:10.10.10.255 \
    alpine:latest cat /etc/resolv.conf

## use --add-host to add custom mapping of ip address and hostnameo
## both --hostname and --add-host and other custom mapping live in /etc/hosts
docker run --rm \
    --hostname barker \
    --add-host test:10.10.10.255 \
    alpine:latest cat /etc/hosts
