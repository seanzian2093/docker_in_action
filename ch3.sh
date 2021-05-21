#! /bin/bash

# iamge as file
# -o to save to a file, or to stdout by default
docker save -o busybox.tar busybox:1.29

docker rmi busybox:1.29
# -i flag to tell load from a file
docker load -i busybox.tar