#! /bin/bash

# 2.1

# --detach or -d to start a container detached mode
# --name to give the container a name instead of random one from docker
docker run --detach --name web nginx:latest
docker run -d --name mailer dockerinaction/ch2_mailer

# --interactive to keep stdin open for the container
# --tty to allocate a virtual terminal for the container
# could be combined as -it
docker run --interactive --tty --link web:web --name web_test busybox:1.29 /bin/sh

# make a HTTP request to web server, i.e. the web container
# -O to output result to a file, - for stdout, terminal
wget -O - http://web:80

# run last and link all 3 containers
# pressl ctrl P Q to bring it to background
docker run -it --name agent --link web:insideweb --link mailer:insidemailer dockerinaction/ch2_agent

# stop a container and wait 1 sec before kill it
docker container stop -t 1 web
docker container stop -t 1 mailer
docker container stop -t 1 agent

# prune stopped container
docker container prune -f

# 2.2 PID namespace
# by default each container has its own PID namespace
docker run -d --name namespaceA busybox:1.29 /bin/sh -c "sleep 30000"
docker exec namespaceA ps
docker run -d --name namespaceB busybox:1.29 /bin/sh -c "nc -l 0.0.0.0 -p 80"
docker exec namespaceB ps

# we could start a container which shares PID namespace with others, e.g. host
docker run --pid host busybox:1.29 ps

# 2.3 Metaconflicts
# rename current namespaceA to namespaceC
docker rename namespaceA namespaceC

# docker create will start a new container but in stopped state.
docker create nginx

# export the container id to an env
CID=$(docker create nginx)
echo $CID

# or to a file using --cidfile flag
docker create --cidfile /tmp/web.cid nginx:latest
cat /tmp/web.cid

# Display container ids
# --latest - display only the latest created, short as -l
# --quiet - display id only, short as -q
# --no-trunc - display full id instead of first 12 characters.
docker ps --latest --quiet --no-trunc

# 2.4 environment-agnostic system
## using --read-only flag to create a container whose file system is unwrittable
docker run -d --name wp --read-only wordpress:5.0.0-php7.2-apache

## use --format to select interested entries
docker inspect --format "{{.State.Running}}" wp

## create a writtable container
docker run -d --name wp_writable wordpress:5.0.0-php7.2-apache
## check changes to the file system
docker container diff wp_writable


docker run -d --name wp2 \
# root fs read-only
    --read-only \
    # mount a writable directory from host file system
    -v /run/apache2/ \
    # provide container an in-memory temp file system
    --tmpfs /tmp \
    wordpress:5.0.0-php7.2-apache

docker run -d --name wpdb -e MYSQL_ROOT_PASSWORD=ch2demo mysql:5.7

docker run -d --name wp3 \
    --link wpdb:mysql \
    -p 8000:80 \
    --read-only \
    -v /run/apache2/ \
    --tmpfs /tmp \
    wordpress:5.0.0-php7.2-apache

# environment injection
## --env to injection env var to a container, -e for short
## env is a shell command to list all environment vars in current execution context
docker run --env MY_ENV='This is a drill' busybox:1.29 env

# 2.5 Durable container
## --restart flag to tell Docker to restart the container accordingly
## always means exponential back-off strategy
docker run -d --name backoff-detector --restart always busybox:1.29 date

## while a container is in restarting state, can not do anything that requires it to be in running state.
docker exec backoff-detector echo just a test

## PID 1 and init program

## one of the init program is supervisord
docker run -d -p 80:80 --name lamp-test tutum/lamp
## top show host PID for each of the processes in the container
docker top lamp-test
## To display PID in container's PID namespace
docker exec lamp-test ps
docker exec lamp-test kill 436

## overwrite default cmd
docker run wordpress:5.0.0-php7.2-apache cat /usr/local/bin/docker-entrypoint.sh
## overwrite entrypoint, overwrite cmd to provide argument to the new entrypoint 
docker run --entrypoint="cat" wordpress:5.0.0-php7.2-apache /usr/local/bin/docker-entrypoint.sh

# 2.6 clean up
## to remove a stopped container; error if the container is running
docker rm wp
## use --rm flag to docker run to automatically remove container after exits
docker run --rm --name auto-remove-test busybox:1.29 echo hello world
## a compose of quick cleanup
docker rm -vf $(docker ps -a -q)
