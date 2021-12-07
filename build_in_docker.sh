#!/bin/bash

set -x -e

TARGET=$1
if [ -z $TARGET ]; then
	TARGET=all
fi

PWD=`pwd`
USER_NAME=`whoami`
USER_ID=`id -u`


IMAGE=linux-kernel-dev
BUILD_DIR=/tmp/linux-kernel

docker build -t $IMAGE --build-arg USER_NAME=$USER_NAME --build-arg USER_ID=$USER_ID .
docker run -t --rm -v $PWD:$BUILD_DIR $IMAGE bash -c \
	"source scl_source enable devtoolset-7 && make -C $BUILD_DIR $TARGET"
