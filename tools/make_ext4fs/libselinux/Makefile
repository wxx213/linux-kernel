
common_HOST_FILES := \
    callbacks.c \
    check_context.c \
    freecon.c \
    init.c \
    label.c \
    label_file.c \
    label_android_property.c


common_HOST_OBJ_FILES := \
    callbacks.o \
    check_context.o \
    freecon.o \
    init.o \
    label.o \
    label_file.o \
    label_android_property.o

LOCAL_C_INCLUDES := include

libselinux.a: $(common_HOST_OBJ_FILES)
	ar -rc $@ $^

$(common_HOST_OBJ_FILES): $(common_HOST_FILES)
	gcc $(LOCAL_CFLAGS) -c -I$(LOCAL_C_INCLUDES) -DHOST $^

clean:
	rm -f *.o
	rm -f libselinux.a
