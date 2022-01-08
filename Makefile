TOPDIR := $(shell pwd)
OUT_DIR := $(TOPDIR)/out
OUT_OBJ_DIR := $(OUT_DIR)/obj

KERNEL_DIR := $(TOPDIR)/linux-stable
KERNEL_OUT_DIR := $(OUT_OBJ_DIR)/KERNEL_OBJ
KERNEL_OBJ_IMAGE := $(KERNEL_OUT_DIR)/arch/x86/boot/bzImage
KERNEL_IMAGE := $(OUT_DIR)/bzImage

BUSYBOX_DIR := $(TOPDIR)/rootfs/busybox
BUSYBOX_OUT_DIR := $(OUT_DIR)/busybox
BUSYBOX_OBJ_DIR := $(OUT_OBJ_DIR)/BUSYBOX_OBJ

CENTOS_DIR := $(TOPDIR)/centos
CENTOS_OUT_DIR := $(OUT_DIR)/centos
CENTOS_PREPARED ?= no

ROOTFS_OUT_DIR := $(BUSYBOX_OUT_DIR)
INITRD_OUT_DIR := $(OUT_DIR)/initrd

ROOTFS_IMAGE := $(OUT_DIR)/qemu-root.img
INITRD_IMGE := $(OUT_DIR)/initrd.img
VIRTIO_DISK := $(OUT_DIR)/virtio-disk.immg

MAKE_EXT4FS := $(TOPDIR)/tools/make_ext4fs/make_ext4fs

QEMU_DIR := $(TOPDIR)/qemu/qemu-2.12.1
QEMU_OUT_DIR := $(OUT_DIR)/qemu
QEMU_EXE := $(QEMU_OUT_DIR)/usr/local/bin/qemu-system-x86_64
QEMU_IMG_EXE := $(QEMU_OUT_DIR)/usr/local/bin/qemu-img

KVMSAMPLE_OBJ_DIR := $(OUT_OBJ_DIR)/kvmsample
KVMSAMPLE_DIR := $(TOPDIR)/doc/qemu/kvm/sample
KVMSAMPLE_BIN_DIR := $(ROOTFS_OUT_DIR)/usr

NESTED_KVM_DIR := $(OUT_DIR)/nested_kvm_test

KVM_DEVICE = $(shell ls /dev/kvm)
ifneq ($(KVM_DEVICE), )
KVM_OPTION = -enable-kvm -cpu qemu64,svm=on,npt=on
else
KVM_OPTION =
endif

ifneq ($(wildcard /var/.indocker), )
SHARE_OPTION = -fsdev local,security_model=passthrough,id=fsdev0,path=/var/share -device virtio-9p-pci,id=fs0,fsdev=fsdev0,mount_tag=hostshare
else
SHARE_OPTION =
endif

CPUS = $(shell cat /proc/cpuinfo | grep processor | wc -l)
MAC = $(shell echo 52:`od /dev/urandom -w5 -tx1 -An|head -n 1|sed -e 's/ //' -e 's/ /:/g'`)

EXPORT_TOPDIR := $(TOPDIR)
EXPORT_OUT_DIR := $(OUT_DIR)
EXPORT_ROOTFS_OUT_DIR := $(ROOTFS_OUT_DIR)
EXPORT_KERNEL_IMAGE := $(KERNEL_IMAGE)
EXPORT_INITRD_OUT_DIR := $(INITRD_OUT_DIR)

export EXPORT_TOPDIR EXPORT_OUT_DIR EXPORT_ROOTFS_OUT_DIR EXPORT_KERNEL_IMAGE EXPORT_INITRD_OUT_DIR

install:
	$(QEMU_EXE) -smp 2 -m 4096M -kernel $(KERNEL_IMAGE) -nographic -append "root=/dev/vda rw \
	rootfstype=ext4 console=ttyS0 crashkernel=64M@16M"  $(KVM_OPTION) \
	-drive file=$(ROOTFS_IMAGE),if=none,id=drive-virtio-disk0 \
	-device virtio-blk-pci,scsi=off,num-queues=2,drive=drive-virtio-disk0,id=virtio-disk0,\
	disable-legacy=on,disable-modern=off,iommu_platform=on,ats=on \
	-drive file=$(VIRTIO_DISK),if=none,id=drive-virtio-disk1 \
	-device virtio-blk-pci,scsi=off,num-queues=2,drive=drive-virtio-disk1,id=virtio-disk1 \
	-netdev tap,id=hostnet0,script=$(QEMU_OUT_DIR)/etc/qemu-ifup,downscript=$(QEMU_OUT_DIR)/etc/qemu-ifdown -device virtio-net-pci,netdev=hostnet0,id=net0,mac=$(MAC) \
	$(SHARE_OPTION) \
	# -serial unix:$(OUT_DIR)/serial.sock,server,nowait

all: kernel qemu-x initrd centos-rootfs
	echo "build comple, run make to start the vm"

kernel: 
	mkdir -p $(KERNEL_OUT_DIR)
	make -C $(KERNEL_DIR) ARCH=x86 O=$(KERNEL_OUT_DIR) x86_64_defconfig
	make -C $(KERNEL_DIR) ARCH=x86 O=$(KERNEL_OUT_DIR) bzImage -j$(CPUS)
	make -C $(KERNEL_DIR) ARCH=x86 O=$(KERNEL_OUT_DIR) modules -j$(CPUS)
	cp $(KERNEL_OBJ_IMAGE) $(KERNEL_IMAGE)

$(MAKE_EXT4FS):
	make -C $(TOPDIR)/tools/make_ext4fs

busybox:
	mkdir -p $(BUSYBOX_OBJ_DIR)
	make -C $(BUSYBOX_DIR) ARCH=x86 O=$(BUSYBOX_OBJ_DIR) USR_CUST_TARGET=rootfs CONFIG_STATIC=y -j$(CPUS) defconfig
	make -C $(BUSYBOX_DIR) ARCH=x86 O=$(BUSYBOX_OBJ_DIR) USR_CUST_TARGET=rootfs CONFIG_STATIC=y \
	CONFIG_PREFIX=$(BUSYBOX_OUT_DIR) -j$(CPUS) install

rootfs: busybox $(MAKE_EXT4FS)
	# dd if=/dev/zero of=$(ROOTFS_OBJ_OUT)/disks/qemu-root bs=1024K count=1000
	#  mkfs.ext4 $(ROOTFS_OBJ_OUT)/disks/qemu-root
	# sudo mount -o loop $(ROOTFS_OBJ_OUT)/disks/qemu-root $(ROOTFS_OBJ_OUT)/mnt/qemu-root/
	# sudo cp -r $(BUSYBOX_OUT_DIR)/* $(ROOTFS_OBJ_OUT)/mnt/qemu-root/
	# sudo umount $(ROOTFS_OBJ_OUT)/mnt/qemu-root
	# dd if=/dev/zero of=$(VIRTIO_DISK) bs=1024K count=1000
	make -C $(TOPDIR)/debug -j$(CPUS)
	cp $(INITRD_IMGE) $(BUSYBOX_OUT_DIR)/usr/
	$(MAKE_EXT4FS) -l 20G $(ROOTFS_IMAGE) $(BUSYBOX_OUT_DIR)
	# $(QEMU_IMG_EXE) convert -f raw -O qcow2 $(ROOTFS_IMAGE) $(ROOTFS_IMAGE)
	$(QEMU_IMG_EXE) create -f qcow2 $(VIRTIO_DISK) 1G

centos-rootfs: $(MAKE_EXT4FS)
ifeq ($(CENTOS_PREPARED), no)
	sudo rm -rf $(CENTOS_OUT_DIR)/*
	./prepare_centos.sh $(CENTOS_OUT_DIR)
endif
	sudo make -C $(KERNEL_DIR) ARCH=x86 O=$(KERNEL_OUT_DIR) modules_install INSTALL_MOD_PATH=$(CENTOS_OUT_DIR)
	# need to run with root, or there will be problem with the rootfs
	sudo $(MAKE_EXT4FS) -l 20G $(ROOTFS_IMAGE) $(CENTOS_OUT_DIR)
	$(QEMU_IMG_EXE) create -f qcow2 $(VIRTIO_DISK) 1G

initrd:
	mkdir -p $(BUSYBOX_OBJ_DIR)
	mkdir -p $(INITRD_OUT_DIR)
	make -C $(BUSYBOX_DIR) ARCH=x86 O=$(BUSYBOX_OBJ_DIR) USR_CUST_TARGET=initrd CONFIG_STATIC=y -j$(CPUS) defconfig
	make -C $(BUSYBOX_DIR) ARCH=x86 O=$(BUSYBOX_OBJ_DIR) USR_CUST_TARGET=initrd CONFIG_STATIC=y \
	CONFIG_PREFIX=$(INITRD_OUT_DIR) -j$(CPUS) install
	(cd $(INITRD_OUT_DIR); find . | cpio -o -H newc | gzip) > $(INITRD_IMGE)

disk-mount:
	mkdir -p $(OUT_DIR)/disks
	sudo mount -o loop $(ROOTFS_IMAGE) $(OUT_DIR)/disks/

crash_debug:
	mkdir -p $(OUT_DIR)/disks
	sudo mount -o loop $(ROOTFS_IMAGE) $(OUT_DIR)/disks/
	sudo crash $(KERNEL_OUT_DIR)/vmlinux $(OUT_DIR)/disks/tmp/vmcore
	sudo umount $(OUT_DIR)/disks/

disk-umount:
	sudo umount $(OUT_DIR)/disks/

qemu-x:
	mkdir -p $(QEMU_OUT_DIR)
	cd $(QEMU_DIR) && $(QEMU_DIR)/configure --target-list="i386-softmmu x86_64-softmmu" --enable-virtfs
	cd $(QEMU_DIR) && make -j$(CPUS)
	cd $(QEMU_DIR) && make DESTDIR=$(QEMU_OUT_DIR) install
	install -D $(QEMU_DIR)/usr_cust/etc/qemu-ifup $(QEMU_OUT_DIR)/etc/qemu-ifup
	install -D  $(QEMU_DIR)/usr_cust/etc/qemu-ifdown $(QEMU_OUT_DIR)/etc/qemu-ifdown

kvmsample:
	make -C $(KVMSAMPLE_DIR) O=$(KVMSAMPLE_OBJ_DIR)
	mkdir -p $(KVMSAMPLE_BIN_DIR)
	cp $(KVMSAMPLE_OBJ_DIR)/kvmsample $(KVMSAMPLE_BIN_DIR)/
	cp $(KVMSAMPLE_OBJ_DIR)/test.bin $(KVMSAMPLE_BIN_DIR)/

container_rootfs:
	mkdir -p $(BUSYBOX_OBJ_DIR)
	mkdir -p $(OUT_DIR)/container_sample/busybox
	make -C $(BUSYBOX_DIR) ARCH=x86 O=$(BUSYBOX_OBJ_DIR) USR_CUST_TARGET=container_rootfs \
	CONFIG_STATIC=y CONTAINER_ROOTFS_OUT_DIR=$(OUT_DIR)/container_sample/busybox defconfig
	make -C $(BUSYBOX_DIR) ARCH=x86 O=$(BUSYBOX_OBJ_DIR) USR_CUST_TARGET=container_rootfs \
	CONFIG_STATIC=y CONFIG_PREFIX=$(OUT_DIR)/container_sample/busybox \
	CONTAINER_ROOTFS_OUT_DIR=$(OUT_DIR)/container_sample/busybox install
	mkdir -p $(OUT_DIR)/container_sample/root

container_sample:
	gcc $(TOPDIR)/doc/container/sample/main.c -o  $(OUT_DIR)/container_sample/create_container
	cd $(OUT_DIR)/container_sample && ./create_container

nested-kvm:
	mkdir -p $(NESTED_KVM_DIR)
	cp $(QEMU_EXE) $(NESTED_KVM_DIR)/
	cp $(QEMU_DIR)/pc-bios/linuxboot_dma.bin $(NESTED_KVM_DIR)/
	cp $(QEMU_DIR)/pc-bios/bios-256k.bin $(NESTED_KVM_DIR)/
	cp $(QEMU_DIR)/pc-bios/kvmvapic.bin $(NESTED_KVM_DIR)/
	cp $(QEMU_DIR)/pc-bios/vgabios-stdvga.bin $(NESTED_KVM_DIR)/
	cp $(KERNEL_IMAGE) $(NESTED_KVM_DIR)/
	cp $(QEMU_DIR)/pc-bios/efi-e1000.rom $(NESTED_KVM_DIR)/
	$(MAKE_EXT4FS) -l 2G $(NESTED_KVM_DIR)/qemu-root.img $(BUSYBOX_OUT_DIR)
	$(MAKE_EXT4FS) -l 4G $(SCSI_DISK) $(NESTED_KVM_DIR)

clean:
	rm -rf $(OUT_DIR)
	cd $(QEMU_DIR) && $(QEMU_DIR)/configure --target-list="i386-softmmu x86_64-softmmu"
	cd $(QEMU_DIR) && make distclean
	make clean -C $(TOPDIR)/debug
	make clean -C $(TOPDIR)/tools/make_ext4fs

help:
	@echo "make                - equal to make insall"
	@echo "make all            - build all and start qemu with the build kernel and rootfs"
	@echo "make install        - only start qemu with the build kernel and rootfs"
	@echo "make kernel         - build kernel"
	@echo "make rootfs         - build busybox rootfs"
	@echo "make centos-rootfs  - build centos rootfs to replace the busybox rootfs"
	@echo "make initrd         - build initrd"
	@echo "make qemu-x         - build qemu"
	@echo "make kvmsample      - build kvm sample codes"
	@echo "make nested-kvm     - build nested kvm test codes"
	@echo "make clean          - clean all the builds"
	@echo "for more help information, see doc/env/build_env.txt"
