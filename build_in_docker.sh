#!/bin/bash

set -x -e

TARGETS=$1

if [ -z $TARGETS ]; then
	TARGETS="install"
elif [ $TARGETS == "all" ]; then
	TARGETS="kernel qemu-x centos-rootfs"
fi

PWD=`pwd`
# USER_NAME=`whoami`
# USER_ID=`id -u`
USER_NAME="root"
USER_ID="0"

IMAGE=linux-kernel-dev
BUILD_DIR=/tmp/linux-kernel

CENTOS_PREPARED="no"

docker build -t $IMAGE --build-arg USER_NAME=$USER_NAME --build-arg USER_ID=$USER_ID -f Dockerfile.build .

for TARGET in $TARGETS; do
	if [ $TARGET == centos-rootfs ]; then
		docker run -ti --rm -v $PWD:$BUILD_DIR $IMAGE bash -c "mkdir -p $BUILD_DIR/out && chmod +666 $BUILD_DIR/out"
		./prepare_centos.sh $PWD/out/centos
		CENTOS_PREPARED="yes"
	fi
	docker run -ti --rm -v $PWD:$BUILD_DIR $IMAGE bash -c \
			"source scl_source enable devtoolset-7 && make CENTOS_PREPARED=$CENTOS_PREPARED -C $BUILD_DIR $TARGET"
done
