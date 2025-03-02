#!/bin/bash 
echo "Destroying EVERYTHING in Docker........"
for i in `docker ps | grep -v CONT | awk {' print $1 '}`; do docker rm -f $i  ; done
docker system prune -a && docker volume prune 
docker ps 
docker images
for i in `docker volume ls --quiet` ; do docker volume rm -f $i ; done
docker volume ls
rm -rf /tmp/config/