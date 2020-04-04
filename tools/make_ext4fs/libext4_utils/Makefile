
libext4_utils_src_files := \
    make_ext4fs.c \
    ext4fixup.c \
    ext4_utils.c \
    allocate.c \
    contents.c \
    extent.c \
    indirect.c \
    uuid.c \
    sha1.c \
    wipe.c \
    crc16.c \
    ext4_sb.c

libext4_utils_obj_files := \
    make_ext4fs.o \
    ext4fixup.o \
    ext4_utils.o \
    allocate.o \
    contents.o \
    extent.o \
    indirect.o \
    uuid.o \
    sha1.o \
    wipe.o \
    crc16.o \
    ext4_sb.o

LOCAL_C_INCLUDES := include

libsparse_path := ../libsparse
libsparse_includes := ../libsparse/include

libselinux_path := ../libselinux
libselinux_includes := ../libselinux/include

libext4_utils.a: $(libext4_utils_obj_files)
	ar -rc $@ $^

$(libext4_utils_obj_files): $(libext4_utils_src_files)
	gcc -c -I$(libsparse_includes) -I$(libselinux_includes) -I$(LOCAL_C_INCLUDES) \
	-L$(libsparse_path) -L$(libselinux_path) -lsparse -l selinux -DHOST $^

clean:
	rm -f *.o
	rm -f libext4_utils.a
