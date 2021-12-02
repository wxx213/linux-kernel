#!/bin/bash

set -x -e

TARGET=$1
if [ -z $TARGET ]; then
	TARGET=all
fi

PWD=`pwd`
USER_NAME=`whoami`

IMAGE=linux-kernel-dev
BUILD_DIR=/tmp/linux-kernel

docker build -t $IMAGE --build-arg USER_NAME=$USER_NAME .
docker run -t --rm -v $PWD:$BUILD_DIR $IMAGE bash -c \
	"source scl_source enable devtoolset-7 && make -C $BUILD_DIR $TARGET"
