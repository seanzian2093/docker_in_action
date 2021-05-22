

# 7.1 Build Docker image from a container

## Any changes made to filesystem in a container will be written as new UFS layers owned by that container.
## UFS a.k.a union filesystem

## Create a new file in a container
docker container run \
    --name hw_container \
    ubuntu:18.04 \
    touch /HelloWorld
## use docker container commit subcommmand to create a new image from the modified container
docker container commit hw_container hw_image
docker rm -vf hw_container 
docker container run --rm hw_image ls -l /HelloWorld


## start a container
docker container run -it \
    --name image-dev \
    ubuntu:18.04 /bin/bash
## within container install git
apt-get update && apt-get install -y git && exit
## check changes to the filesystem in the container - A means added file, D means delted, C means changed
docker container diff image-dev
## commit the changes and built a new image from it
## -a flog to add author info, -m commit message
docker container commit -a "seanz" -m "Added git" image-dev ubuntu-git
## check
docker container run --rm ubuntu-git git version
## but ubuntu-git default command is /bin/bash && exit
docker container run --rm ubuntu-git

## now start a new container with entrypoint using --entrypoint flag
docker container run \
    --name cmd-git \
    --entrypoint git \
    ubuntu-git

docker container commit -m "Set CMD git" \
    -a "seanz" cmd-git ubuntu-git


docker container run --rm ubuntu-git version

## docker commit could also include
## environment variable
## wokring directory
## set of exposed ports
## volume
## entrypoint
## command and arguments

## use docker image history subcommand to view layers
docker image history ubuntu-git

## 7.3 Export and import flat filesystem
docker container create \
    --name export-test \
    dockerinaction/ch7_packed:latest ./echo For Export

## export a container to a tar file
## use --output or -o to output to a file; if not specified, to stdout, console
docker container export \
    --output contents.tar \
    export-test

docker container rm export-test

## list contents of a tar file
tar -tvf contents.tar

## import sumcommand stream content of a tarball into a new image
## create a helloworld.go file in pwd
## use a golang container to build it t executable
docker container run --rm \
    -v "$(pwd)":/usr/src/hello \
    -w /usr/src/hello \
    golang:1.9 go build -v

## put executable into a tarball
tar -cf static_hello.tar hello

## import the tarball to a image
## -c flag to specify Dockerfile command
docker import -c "ENTRYPOINT [\"/hello\"]" - \
    dockerinaction/ch7_static < static_hello.tar

## check the image by starting a container
docker container run dockerinaction/ch7_static
docker image history dockerinaction/ch7_static