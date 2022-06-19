# 创建虚拟机镜像

创建空的虚拟机镜像文件，大小为20G，文件名为openeuler.img

```shell
qemu-img create openeuler.img 20G
```

启动虚拟机安装镜像，启动后vnc server监听的端口为5901（5900 + 1）

```shell
qemu-system-x86_64 -smp 1 -m 2048 -enable-kvm -nographic -hda openeuler.img -cdrom openEuler-22.03-LTS-x86_64-dvd.iso -vnc :1
```

通过vnc client连接vnc端口，按照提示装机即可，装机完成后在内核命令行添加"console=ttyS0"，使得内核日志可以被qemu打印在标准输出



# 启动虚拟机

启动

```shell
# 提供vnc连接方式，通过vnc client连接vnc 5901端口
qemu-system-x86_64 -smp 1 -m 2048M -nographic -enable-kvm -hda openeuler.img -vnc :1

# 提供ssh连接方式，通过ssh命令连接
qemu-system-x86_64 -smp 1 -m 2048M -nographic -enable-kvm -hda openeuler.img -net nic -net user,hostfwd=tcp::10022-:22

ssh -p 10022 root@localhost
```


