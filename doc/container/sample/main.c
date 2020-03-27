#define _GNU_SOURCE
#include <sys/types.h>
#include <sys/wait.h>
#include <stdio.h>
#include <sched.h>
#include <signal.h>
#include <unistd.h>
#include <stdlib.h>
#include <sys/stat.h>
#include <fcntl.h>
#include <string.h>
#include <sys/mount.h>
#include <signal.h>

#define STACK_SIZE (1024 * 1024)
#define PATH_MAX_LEN 30
#define UID_MAP "0 1000 1"
#define GID_MAP "0 1000 1"

static char container_stack[STACK_SIZE];
char* const container_args[] = {
	// "/sbin/init",
	"/bin/sh",
	NULL
};

static int prepare_dev_root()
{
	int ret;

	ret = system("dd if=/dev/zero of=container_root bs=1024K count=1000");
	if(ret) {
		perror("dd if=/dev/zero of=container_root bs=1024K count=1000 error");
		return ret;
	}
	ret = system("losetup /dev/loop2020 container_root");
	if(ret) {
		perror("losetup /dev/loop2020 container_root error");
		return ret;
	}
	ret = system("mkfs.ext4 /dev/loop2020");
	if(ret) {
		perror("mkfs.ext4 /dev/loop2020 error");
		return ret;
	}
	ret = system("mkdir -p container_rootfs");
	if(ret) {
		perror("mkdir container_rootfs error");
		return ret;
	}
	// ret = system("mount -o loop container_root container_rootfs/");
	ret = system("mount /dev/loop2020 container_rootfs/");
	if(ret) {
		// perror("mount container_root container_rootfs/ error");
		perror("mount /dev/loop2020 container_rootfs/ error");
		return ret;
	}
	ret = system("cp -r busybox/* container_rootfs/");
	if(ret) {
		perror("cp -r busybox/* container_rootfs/ error");
		return ret;
	}
	return 0;
}

static int prepare_bind_mount_root()
{
	int ret;

	ret = system("mkdir -p container_rootfs");
	if(ret) {
		perror("mkdir container_rootfs error");
		return ret;
	}

	ret = system("mount -B busybox container_rootfs/");
	if(ret) {
		perror("mount busybox container_rootfs/ error");
		return ret;
	}
	return 0;
}

static int prepare_directory_root()
{
	int ret;

	ret = system("mkdir -p container_rootfs");
	if(ret) {
		perror("mkdir container_rootfs error");
		return ret;
	}
    ret = system("cp -r busybox/* container_rootfs/");
	if(ret) {
		perror("cp -r busybox/* container_rootfs/ error");
		return ret;
	}
	return 0;
}

static int cleanup_root()
{
	int ret;

	ret = system("umount container_rootfs");
	if(ret) {
		perror("umount container_rootfs error");
		return ret;
	}

	ret = system("losetup -d /dev/loop2020");
	if(ret) {
		perror("losetup -d /dev/loop2020 error");
	}
	return 0;
}

static int set_as_root()
{
	int ret;

	printf("current pid is %d\n", getpid());
	ret = setuid(0);
	if(ret < 0) {
		perror("setuid failed");
		return 1;
	}
	ret = setgid(0);
	if(ret < 0) {
		perror("setgid failed");
		return 1;
	}
	printf("setuid setgid finished\n");
	return 0;
}

static int switch_to_rootfs()
{
	int ret;

	ret = chdir("container_rootfs");
	if(ret < 0) {
		perror("chdir container_rootfs failed");
		return 1;
	}
	ret = chroot(".");
	if(ret < 0) {
		perror("chroot . failed");
		return 1;
	}
	ret = chdir("/");
	if(ret < 0) {
		perror("chdir / failed");
		return 1;
	}
	return 0;
}

static int prepare_devfs()
{
	int ret;

	ret = mount("none", "/dev", "tmpfs", 0, NULL);
	if(ret < 0) {
		perror("mount /dev failed");
		return 1;
	}
	ret = mknod("/dev/console", 0x777, makedev(5, 1));
	if(ret < 0) {
		perror("mknod console failed");
		return 1;
	}
	ret = mknod("/dev/tty", 0x777, makedev(5, 0));
	if(ret < 0) {
		perror("mknod tty failed");
		return 1;
	}
	ret = mknod("/dev/tty1", 0x777, makedev(4, 1));
	if(ret < 0) {
		perror("mknod tty1 failed");
		return 1;
	}
	ret = mknod("/dev/tty2", 0x777, makedev(4, 2));
	if(ret < 0) {
		perror("mknod tty2 failed");
		return 1;
	}
	ret = mknod("/dev/tty3", 0x777, makedev(4, 3));
	if(ret < 0) {
		perror("mknod tty3 failed");
		return 1;
	}
	ret = mknod("/dev/tty4", 0x777, makedev(4, 4));
	if(ret < 0) {
		perror("mknod tty4 failed");
		return 1;
	}
	ret = mknod("/dev/null", 0x777, makedev(1, 3));
	if(ret < 0) {
		perror("mknod null failed");
		return 1;
	}
	return 0;
}

static int  prepare_proc_sysfs()
{
	int ret;

	ret = mount("proc", "/proc", "proc", 0, NULL);
	if(ret < 0) {
		perror("mount proc failed");
		return 1;
	}

	ret = mount("sysfs", "/sys", "sysfs", 0, NULL);
	if(ret < 0) {
		perror("mount sysfs failed");
		return 1;
	}
	return 0;
}

static int setup_gid_pid(pid_t pid)
{
	int fd, ret;
	char path[PATH_MAX_LEN];

	snprintf(path, PATH_MAX_LEN, "/proc/%d/uid_map", pid);
	fd = open(path, O_RDWR);
	if(fd < 0) {
		perror("open /proc/pid/uid_map failed");
		kill(pid, SIGKILL);
		return 1;
	}
	ret = write(fd, UID_MAP, strlen(UID_MAP));
	if(ret < 0) {
		perror("write /proc/pid/uid_map failed");
		close(fd);
		kill(pid, SIGKILL);
		return 1;
	}
	close(fd);

	snprintf(path, PATH_MAX_LEN, "/proc/%d/setgroups", pid);
	fd = open(path, O_RDWR);
	if(fd < 0) {
		perror("open /proc/pid/setgroups failed");
		printf("open /proc/%d/setgroups error\n", pid);
		while(1);
		kill(pid, SIGKILL);
		return 1;
	}
	ret = write(fd, "deny", strlen("deny"));
	if(ret < 0) {
		perror("write /proc/pid/setgroups failed");
		close(fd);
		kill(pid, SIGKILL);
		return 1;
	}
	close(fd);

	snprintf(path, PATH_MAX_LEN, "/proc/%d/gid_map", pid);
	fd = open(path, O_RDWR);
	if(fd < 0) {
		perror("open /proc/pid/gid_map failed");
		kill(pid, SIGKILL);
		return 1;
	}
	ret = write(fd, GID_MAP, strlen(GID_MAP));
	if(ret < 0) {
		perror("write /proc/pid/gid_map failed");
		close(fd);
		kill(pid, SIGKILL);
		return 1;
	}
	close(fd);
	printf("set uid_map gid_map finished\n");
	return 0;
}

// the container process
int container_main(void *args)
{
	int ret;

	printf("In container process\n");
	sethostname("container", 9);

	// delay to wait for setting /proc/$pid/uid_map and /proc/$pid/gid_map
	// complete by parent process
	sleep(1);
	ret = set_as_root();
	if(ret) {
		perror("set_as_root error");
		exit(1);
	}
#if 0
	ret = mount("busybox", "root", 0, MS_BIND, NULL);
	if(ret < 0) {
		perror("mount bind failed");
		exit(1);
	}
#endif
	ret = switch_to_rootfs();
	if(ret) {
		perror("switch_to_rootfs error");
		exit(1);
	}

	ret = prepare_devfs();
	if(ret) {
		perror("prepare_devfs error");
		exit(1);
	}

	ret = prepare_proc_sysfs();
	if(ret) {
		perror("prepare_proc_sysfs error");
		exit(1);
	}
	execv(container_args[0], container_args);
}

int main(int args, char *argv[])
{
	int ret;

	printf("Program start\n");

	ret = prepare_dev_root();
	// ret = prepare_directory_root();
	// ret = prepare_bind_mount_root();
	if(ret) {
		perror("prepare_root failed");
		return 1;
	}
	// clone container process
	int container_pid = clone(container_main, container_stack + STACK_SIZE, SIGCHLD
		| CLONE_NEWUTS
		| CLONE_NEWUSER
		| CLONE_NEWPID
		| CLONE_NEWNS
		| CLONE_NEWIPC
		| CLONE_NEWNET
		, NULL);

	if(container_pid < 0) {
		perror("clone failed");
		return 1;
	}

	ret = setup_gid_pid(container_pid);
	if(ret) {
		perror("setup_gid_pid error");
		exit(1);
	}
	// wait for container process end
	waitpid(container_pid, NULL, 0);
	cleanup_root();
	return 0;
}
