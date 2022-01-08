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

if [ $TARGETS == "runtime-image" ]; then
	docker build -t linux-kernel-runtime --build-arg USER_NAME=root --build-arg USER_ID=0 -f Dockerfile.runtime .
	exit 0
fi

docker build -t $IMAGE --build-arg USER_NAME=$USER_NAME --build-arg USER_ID=$USER_ID -f Dockerfile.build .

for TARGET in $TARGETS; do
	if [ $TARGET == centos-rootfs ]; then
		docker run -ti --rm -v $PWD:$BUILD_DIR $IMAGE bash -c "mkdir -p $BUILD_DIR/out && chmod +666 $BUILD_DIR/out && rm -rf $BUILD_DIR/out/centos/*"
		./prepare_centos.sh $PWD/out/centos
		CENTOS_PREPARED="yes"
	fi
	docker run -ti --rm -v $PWD:$BUILD_DIR --cap-add NET_ADMIN --device /dev/net/tun:/dev/net/tun:rw \
		--device /dev/kvm:/dev/kvm:rw  $IMAGE bash -c \
		"source scl_source enable devtoolset-7 && make CENTOS_PREPARED=$CENTOS_PREPARED -C $BUILD_DIR $TARGET"
done
