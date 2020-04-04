
LOCAL_SRC_FILES := make_ext4fs_main.c canned_fs_config.c
LOCAL_STATIC_LIBRARIES := \
    libext4_utils/libext4_utils.a \
    libsparse/libsparse.a \
	libselinux/libselinux.a

make_ext4fs: $(LOCAL_SRC_FILES) $(LOCAL_STATIC_LIBRARIES)
	gcc $(LOCAL_SRC_FILES) -Llibext4_utils -Llibsparse -Llibselinux \
	-Ilibext4_utils/include -Ilibsparse/include -Ilibselinux/include \
	-lext4_utils -lsparse -lselinux -lz -lpcre -DHOST -o make_ext4fs

libext4_utils/libext4_utils.a:
	make -C libext4_utils

libsparse/libsparse.a:
	make -C libsparse

libselinux/libselinux.a:
	make -C libselinux

clean:
	rm -f *.o
	rm -f make_ext4fs
	make -C libext4_utils clean
	make -C libsparse clean
	make -C libselinux clean
