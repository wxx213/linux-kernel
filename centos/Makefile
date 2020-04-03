
CURR = $(shell pwd)
ROOTFS = $(CURR)/rootfs

all:
	docker build -t centos_rootfs -f Dockerfile .
	docker create --name centos_rootfs centos_rootfs
	mkdir -p $(ROOTFS)
	sudo rm -rf $(ROOTFS)/*
	docker export -o centos_rootfs.tar centos_rootfs
	tar -C $(ROOTFS) -xvf centos_rootfs.tar
	rm centos_rootfs.tar
	docker rm -f centos_rootfs
