libsparse_src_files := \
        backed_block.c \
        output_file.c \
        sparse.c \
        sparse_crc32.c \
        sparse_err.c \
        sparse_read.c

libsparse_obj_files := \
        backed_block.o \
        output_file.o\
        sparse.o \
        sparse_crc32.o \
        sparse_err.o \
        sparse_read.o

LOCAL_C_INCLUDES := include # external/zlib

LOCAL_CFLAGS := -Werror

libsparse.a: $(libsparse_obj_files)
	ar -rc $@ $^ 

$(libsparse_obj_files): $(libsparse_src_files)
	gcc $(LOCAL_CFLAGS) -c -I$(LOCAL_C_INCLUDES) -DHOST $^

clean:
	rm -f *.o
	rm -f libsparse.a
