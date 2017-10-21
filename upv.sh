#!/usr/bin/env bash

source functions.sh

echo "Starting upv..."
docker build -qt upv docker/upv
docker run -it --network host \
           -v `pwd`:/upv/workspace \
           -v /var/run/docker.sock:/var/run/docker.sock \
           upv "$@"
