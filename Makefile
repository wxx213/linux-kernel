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

ROOTFS_IMAGE := $(OUT_DIR)/qemu-root.img
VIRTIO_DISK := $(OUT_DIR)/qemu-virtio.img
SCSI_DISK := $(OUT_DIR)/qemu-scsib.img
MAKE_EXT4FS := make_ext4fs

QEMU_DIR := $(TOPDIR)/qemu/qemu-2.12.1
QEMU_OBJ_DIR := $(OUT_OBJ_DIR)/qemu
QEMU_EXE := $(QEMU_DIR)/x86_64-softmmu/qemu-system-x86_64
QEMU_IMG_EXE := $(QEMU_DIR)/qemu-img

EXPORT_TOPDIR := $(TOPDIR)
EXPORT_OUT_DIR := $(OUT_DIR)
EXPORT_ROOTFS_OUT_DIR := $(ROOTFS_OUT_DIR)
EXPORT_KERNEL_IMAGE := $(KERNEL_IMAGE)

export EXPORT_TOPDIR EXPORT_OUT_DIR EXPORT_ROOTFS_OUT_DIR EXPORT_KERNEL_IMAGE

all: kernel qemu-x rootfs
	$(QEMU_EXE) -smp 2 -m 2048M -kernel $(KERNEL_IMAGE) -nographic -append "root=/dev/sda rootfstype=ext4 \
	 console=ttyS0 crashkernel=64M@16M" -hda \
	$(ROOTFS_IMAGE) -drive file=$(VIRTIO_DISK),if=virtio -hdb $(SCSI_DISK)

install:
	$(QEMU_EXE) -smp 2 -m 2048M -kernel $(KERNEL_IMAGE) -nographic -append "root=/dev/sda rootfstype=ext4 \
	console=ttyS0 crashkernel=64M@16M" -hda \
	$(ROOTFS_IMAGE) -drive file=$(VIRTIO_DISK),if=virtio -hdb $(SCSI_DISK)

kernel: 
	make -C $(KERNEL_DIR) ARCH=x86 O=$(KERNEL_OUT_DIR) x86_64_defconfig
	make -C $(KERNEL_DIR) ARCH=x86 O=$(KERNEL_OUT_DIR) bzImage -j2
	cp $(KERNEL_OBJ_IMAGE) $(KERNEL_IMAGE)

busybox:
	mkdir -p $(BUSYBOX_OBJ_DIR)
	make -C $(BUSYBOX_DIR) ARCH=x86 O=$(BUSYBOX_OBJ_DIR) CONFIG_STATIC=y defconfig
	make -C $(BUSYBOX_DIR) ARCH=x86 O=$(BUSYBOX_OBJ_DIR) CONFIG_STATIC=y CONFIG_PREFIX=$(BUSYBOX_OUT_DIR) install

rootfs: busybox
	# dd if=/dev/zero of=$(ROOTFS_OBJ_OUT)/disks/qemu-root bs=1024K count=1000
	#  mkfs.ext4 $(ROOTFS_OBJ_OUT)/disks/qemu-root
	# sudo mount -o loop $(ROOTFS_OBJ_OUT)/disks/qemu-root $(ROOTFS_OBJ_OUT)/mnt/qemu-root/
	# sudo cp -r $(BUSYBOX_OUT_DIR)/* $(ROOTFS_OBJ_OUT)/mnt/qemu-root/
	# sudo umount $(ROOTFS_OBJ_OUT)/mnt/qemu-root
	# dd if=/dev/zero of=$(VIRTIO_DISK) bs=1024K count=1000
	make -C $(TOPDIR)/debug
	$(MAKE_EXT4FS) -l 6G $(ROOTFS_IMAGE) $(BUSYBOX_OUT_DIR)
	# $(QEMU_IMG_EXE) convert -f raw -O qcow2 $(ROOTFS_IMAGE) $(ROOTFS_IMAGE)
	$(QEMU_IMG_EXE) create -f qcow2 $(VIRTIO_DISK) 1024M
	$(MAKE_EXT4FS) -l 4G $(SCSI_DISK)

# rootfs-mount:
	# sudo mount -o loop $(ROOTFS_OBJ_OUT)/disks/qemu-root $(ROOTFS_OBJ_OUT)/mnt/qemu-root/

# rootfs-umount:
	# sudo umount $(ROOTFS_OBJ_OUT)/mnt/qemu-root

qemu-x:
	cd $(QEMU_DIR) && $(QEMU_DIR)/configure --target-list="i386-softmmu x86_64-softmmu"
	cd $(QEMU_DIR) && make

clean:
	rm -rf $(OUT_DIR)
	cd $(QEMU_DIR) && $(QEMU_DIR)/configure --target-list="i386-softmmu x86_64-softmmu"
	cd $(QEMU_DIR) && make distclean
