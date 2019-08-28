
KEXEC_TOOL_DIR := $(EXPORT_TOPDIR)/debug/kexec-tools

all: kexec_tool

kexec_tool:
	cd $(KEXEC_TOOL_DIR) && ./bootstrap
	cd $(KEXEC_TOOL_DIR) && ./configure
	cd $(KEXEC_TOOL_DIR) && make
	mkdir -p $(EXPORT_ROOTFS_OUT_DIR)/usr/bin $(EXPORT_ROOTFS_OUT_DIR)/usr/local
	cp $(KEXEC_TOOL_DIR)/build/sbin/kexec $(EXPORT_ROOTFS_OUT_DIR)/usr/bin
	cp $(EXPORT_KERNEL_IMAGE) $(EXPORT_ROOTFS_OUT_DIR)/usr/local

clean:
	cd $(KEXEC_TOOL_DIR) && ./bootstrap
	cd $(KEXEC_TOOL_DIR) && ./configure
	cd $(KEXEC_TOOL_DIR) && make clean
	
