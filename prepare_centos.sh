#!/bin/bash

set -e -x

target_dir=$1

if [ -z "$target_dir" ]; then
	echo "Need target directory specified store centos files."
	exit 1
fi

docker build -t centos_rootfs -f Dockerfile.centos .
cid=`docker create centos_rootfs`
mkdir -p $target_dir
docker export -o centos_rootfs.tar $cid
tar -C $target_dir -xvf centos_rootfs.tar
rm centos_rootfs.tar
docker rm -f $cid

