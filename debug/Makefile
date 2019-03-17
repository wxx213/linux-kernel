
KEXEC_TOOL_DIR := $(EXPORT_TOPDIR)/debug/kexec-tools

all: kexec_tool

kexec_tool:
	cd $(KEXEC_TOOL_DIR) && ./bootstrap
	cd $(KEXEC_TOOL_DIR) && ./configure
	cd $(KEXEC_TOOL_DIR) && make
	cp $(KEXEC_TOOL_DIR)/build/sbin/kexec $(EXPORT_ROOTFS_OUT_DIR)/usr/
	cp $(EXPORT_KERNEL_IMAGE) $(EXPORT_ROOTFS_OUT_DIR)/usr/

clean:
	cd $(KEXEC_TOOL_DIR) && ./bootstrap
	cd $(KEXEC_TOOL_DIR) && ./configure
	cd $(KEXEC_TOOL_DIR) && make clean
	
