[TOC]

# Introduction

Linux-kernel is a learning tool for linux kernel and os by starting a VM by qemu with code build kernel and busybox rootfs.

Here are some of the components:

- [qemu](https://github.com/wxx213/qemu-2.12)  the VM creater
- [linux kernel](https://github.com/wxx213/kernel-stable)  include community and centos kernel
- [busybox](https://github.com/wxx213/busybox_rootfs)  the busybox rootfs
- [centos](https://github.com/wxx213/linux-kernel/tree/master/centos)  the centos rootfs, created by docker centos image
- [make_ext4fs](https://github.com/wxx213/linux-kernel/tree/master/tools/make_ext4fs)  the tools to make ext4 fs image based directory

You can use the 'sync' script to download these components codes.

- [sync](https://github.com/wxx213/linux-kernel/blob/master/sync)  download the codes from github
- [sync_gitee](https://github.com/wxx213/linux-kernel/blob/master/sync_gitee)  download the codes from gitee

# Build

The [build_in_docker.sh](https://github.com/wxx213/linux-kernel/blob/master/build_in_docker.sh) script could be used to make a one-click build for the components which will only need docker and a normal network for your host.

You can just type to build the qemu, kernel and busybox rootfs:

```shell
./build_in_docker.sh
```

# Run

After the build complete, you can start the VM by type make command:

```shell
make
```

To exit the VM, by type "Ctrl + A + X"

# Others

## Connect the vm

```shell
nc -U out/serial.sock
```
