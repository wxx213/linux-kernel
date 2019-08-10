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

ROOTFS_OUT_DIR := $(BUSYBOX_OUT_DIR)
INITRD_OUT_DIR := $(OUT_DIR)/initrd

ROOTFS_IMAGE := $(OUT_DIR)/qemu-root.img
VIRTIO_DISK := $(OUT_DIR)/qemu-virtio.img
SCSI_DISK := $(OUT_DIR)/qemu-scsib.img
INITRD_IMGE := $(OUT_DIR)/initrd.img

MAKE_EXT4FS := make_ext4fs

QEMU_DIR := $(TOPDIR)/qemu/qemu-2.12.1
QEMU_OBJ_DIR := $(OUT_OBJ_DIR)/qemu
QEMU_EXE := $(QEMU_DIR)/x86_64-softmmu/qemu-system-x86_64
QEMU_IMG_EXE := $(QEMU_DIR)/qemu-img

KVMSAMPLE_OBJ_DIR := $(OUT_OBJ_DIR)/kvmsample
KVMSAMPLE_DIR := $(TOPDIR)/doc/qemu/kvm/sample
KVMSAMPLE_BIN_DIR := $(ROOTFS_OUT_DIR)/usr

NESTED_KVM_DIR := $(OUT_DIR)/nested_kvm_test

EXPORT_TOPDIR := $(TOPDIR)
EXPORT_OUT_DIR := $(OUT_DIR)
EXPORT_ROOTFS_OUT_DIR := $(ROOTFS_OUT_DIR)
EXPORT_KERNEL_IMAGE := $(KERNEL_IMAGE)
EXPORT_INITRD_OUT_DIR := $(INITRD_OUT_DIR)

export EXPORT_TOPDIR EXPORT_OUT_DIR EXPORT_ROOTFS_OUT_DIR EXPORT_KERNEL_IMAGE EXPORT_INITRD_OUT_DIR

all: kernel qemu-x initrd rootfs
	$(QEMU_EXE) -smp 2 -m 2048M -kernel $(KERNEL_IMAGE) -nographic -append "root=/dev/sda rw rootfstype=ext4 \
	console=ttyS0 crashkernel=64M@16M" -hda $(ROOTFS_IMAGE) -drive file=$(VIRTIO_DISK),if=none,id=drive-virtio-disk0 \
	-device virtio-blk-pci,scsi=off,num-queues=2,drive=drive-virtio-disk0,id=virtio-disk0,disable-legacy=on,\
	disable-modern=off,iommu_platform=on,ats=on -drive file=$(SCSI_DISK),if=none,id=drive-nvme-disk0 \
	-device nvme,drive=drive-nvme-disk0,id=nvme-disk0,serial=usr_cust -enable-kvm -cpu qemu64,svm=on,npt=on \
	# -netdev tap,id=hostnet0,script=$(QEMU_DIR)/usr_cust/etc/qemu-ifup,\
	# downscript=$(QEMU_DIR)/usr_cust/etc/qemu-ifdown \
	# -device virtio-net-pci,netdev=hostnet0,id=net0,mac=52:54:00:66:98:34

install:
	$(QEMU_EXE) -smp 2 -m 2048M -kernel $(KERNEL_IMAGE) -nographic -append "root=/dev/sda rw rootfstype=ext4 \
	console=ttyS0 crashkernel=64M@16M" -hda $(ROOTFS_IMAGE) -drive file=$(VIRTIO_DISK),if=none,id=drive-virtio-disk0 \
	-device virtio-blk-pci,scsi=off,num-queues=2,drive=drive-virtio-disk0,id=virtio-disk0,disable-legacy=on,\
	disable-modern=off,iommu_platform=on,ats=on -drive file=$(SCSI_DISK),if=none,id=drive-nvme-disk0 \
	-device nvme,drive=drive-nvme-disk0,id=nvme-disk0,serial=usr_cust -enable-kvm -cpu qemu64,svm=on,npt=on \
	# -netdev tap,id=hostnet0,script=$(QEMU_DIR)/usr_cust/etc/qemu-ifup,\
	# downscript=$(QEMU_DIR)/usr_cust/etc/qemu-ifdown \
	# -device virtio-net-pci,netdev=hostnet0,id=net0,mac=52:54:00:66:98:34

kernel: 
	make -C $(KERNEL_DIR) ARCH=x86 O=$(KERNEL_OUT_DIR) x86_64_defconfig
	make -C $(KERNEL_DIR) ARCH=x86 O=$(KERNEL_OUT_DIR) bzImage -j2
	cp $(KERNEL_OBJ_IMAGE) $(KERNEL_IMAGE)

busybox:
	mkdir -p $(BUSYBOX_OBJ_DIR)
	make -C $(BUSYBOX_DIR) ARCH=x86 O=$(BUSYBOX_OBJ_DIR) USR_CUST_TARGET=rootfs CONFIG_STATIC=y defconfig
	make -C $(BUSYBOX_DIR) ARCH=x86 O=$(BUSYBOX_OBJ_DIR) USR_CUST_TARGET=rootfs CONFIG_STATIC=y \
	CONFIG_PREFIX=$(BUSYBOX_OUT_DIR) install

rootfs: busybox nested-kvm
	# dd if=/dev/zero of=$(ROOTFS_OBJ_OUT)/disks/qemu-root bs=1024K count=1000
	#  mkfs.ext4 $(ROOTFS_OBJ_OUT)/disks/qemu-root
	# sudo mount -o loop $(ROOTFS_OBJ_OUT)/disks/qemu-root $(ROOTFS_OBJ_OUT)/mnt/qemu-root/
	# sudo cp -r $(BUSYBOX_OUT_DIR)/* $(ROOTFS_OBJ_OUT)/mnt/qemu-root/
	# sudo umount $(ROOTFS_OBJ_OUT)/mnt/qemu-root
	# dd if=/dev/zero of=$(VIRTIO_DISK) bs=1024K count=1000
	make -C $(TOPDIR)/debug
	cp $(INITRD_IMGE) $(BUSYBOX_OUT_DIR)/usr/
	$(MAKE_EXT4FS) -l 6G $(ROOTFS_IMAGE) $(BUSYBOX_OUT_DIR)
	# $(QEMU_IMG_EXE) convert -f raw -O qcow2 $(ROOTFS_IMAGE) $(ROOTFS_IMAGE)
	$(QEMU_IMG_EXE) create -f qcow2 $(VIRTIO_DISK) 1024M

initrd:
	mkdir -p $(BUSYBOX_OBJ_DIR)
	mkdir -p $(INITRD_OUT_DIR)
	make -C $(BUSYBOX_DIR) ARCH=x86 O=$(BUSYBOX_OBJ_DIR) USR_CUST_TARGET=initrd CONFIG_STATIC=y defconfig
	make -C $(BUSYBOX_DIR) ARCH=x86 O=$(BUSYBOX_OBJ_DIR) USR_CUST_TARGET=initrd CONFIG_STATIC=y \
	CONFIG_PREFIX=$(INITRD_OUT_DIR) install
	(cd $(INITRD_OUT_DIR); find . | cpio -o -H newc | gzip) > $(INITRD_IMGE)

disk-mount:
	mkdir -p $(OUT_DIR)/disks
	sudo mount -o loop $(SCSI_DISK) $(OUT_DIR)/disks/

disk-umount:
	sudo umount $(OUT_DIR)/disks/

qemu-x:
	cd $(QEMU_DIR) && $(QEMU_DIR)/configure --target-list="i386-softmmu x86_64-softmmu"
	cd $(QEMU_DIR) && make

kvmsample:
	make -C $(KVMSAMPLE_DIR) O=$(KVMSAMPLE_OBJ_DIR)
	mkdir -p $(KVMSAMPLE_BIN_DIR)
	cp $(KVMSAMPLE_OBJ_DIR)/kvmsample $(KVMSAMPLE_BIN_DIR)/
	cp $(KVMSAMPLE_OBJ_DIR)/test.bin $(KVMSAMPLE_BIN_DIR)/

container_sample:
	rm -rf $(OUT_DIR)/container_sample
	mkdir -p $(OUT_DIR)/container_sample
	gcc $(TOPDIR)/doc/container/sample/main.c -o  $(OUT_DIR)/container_sample/create_container
	cp -r $(ROOTFS_OUT_DIR) $(OUT_DIR)/container_sample/busybox
	mkdir -p $(OUT_DIR)/container_sample/root
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

help:
	@echo "make/make all       - build all and start qemu with the build kernel and rootfs"
	@echo "make install        - only start qemu with the build kernel and rootfs"
	@echo "make kernel         - build kernel"
	@echo "make rootfs         - build rootfs"
	@echo "make initrd         - build initrd"
	@echo "make qemu-x         - build qemu"
	@echo "make kvmsample      - build kvm sample codes"
	@echo "make nested-kvm     - build nested kvm test codes"
	@echo "make clean          - clean all the builds"
	@echo "for more help information, see doc/env/build_env.txt"
