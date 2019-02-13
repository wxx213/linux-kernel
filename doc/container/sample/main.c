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
	"/sbin/init",
	NULL
};

// 容器进程运行的程序主函数
int container_main(void *args)
{
	int ret;

	printf("在容器进程中！\n");
	sethostname("container", 9);

	// delay to wait for setting /proc/$pid/uid_map and /proc/$pid/gid_map
	// complete by parent process
	sleep(1);
	printf("current pid is %d\n", getpid());
	ret = setuid(0);
	if(ret < 0) {
		perror("setuid failed");
		exit(1);
	}
	ret = setgid(0);
	if(ret < 0) {
		perror("setgid failed");
		exit(1);
	}
	printf("setuid setgid finished\n");

#if 1
	ret = mount("busybox", "root", 0, MS_BIND, NULL);
	if(ret < 0) {
		perror("mount bind failed");
		exit(1);
	}
	ret = chdir("root");
	if(ret < 0) {
		perror("chdir root failed");
		exit(1);
	}
	ret = chroot(".");
	if(ret < 0) {
		perror("chroot . failed");
		exit(1);
	}
	ret = chdir("/");
	if(ret < 0) {
		perror("chdir / failed");
		exit(1);
	}
	ret = mount("none", "/dev", "tmpfs", 0, NULL);
	if(ret < 0) {
		perror("mount /dev failed");
		exit(1);
	}
	ret = mknod("/dev/console", 0x777, 0x08800002);
	if(ret < 0) {
		perror("mknod console failed");
		exit(1);
	}
	ret = mknod("/dev/tty", 0x777, 0x00500000);
	if(ret < 0) {
		perror("mknod tty failed");
		exit(1);
	}
	ret = mknod("/dev/tty1", 0x777, 0x08800000);
	if(ret < 0) {
		perror("mknod tty1 failed");
		exit(1);
	}
	ret = mknod("/dev/tty2", 0x777, 0x08800001);
	if(ret < 0) {
		perror("mknod tty2 failed");
		exit(1);
	}
	ret = mknod("/dev/tty3", 0x777, 0x08800002);
	if(ret < 0) {
		perror("mknod tty3 failed");
		exit(1);
	}
	ret = mknod("/dev/tty4", 0x777, 0x08800003);
	if(ret < 0) {
		perror("mknod tty4 failed");
		exit(1);
	}
	ret = mknod("/dev/null", 0x777, 0x00100003);
	if(ret < 0) {
		perror("mknod null failed");
		exit(1);
	}
#endif

#if 0
	ret = mount("proc", "/proc", "proc", 0, NULL);
	if(ret < 0) {
		perror("mount proc failed");
		exit(1);
	}
#endif
	execv(container_args[0], container_args); // 执行/bin/bash   return 1;
}

int main(int args, char *argv[])
{
	int ret, fd;
	pid_t pid;
	char path[PATH_MAX_LEN];

	printf("程序开始\n");
	// clone 容器进程
	int container_pid = clone(container_main, container_stack + STACK_SIZE, SIGCHLD
		| CLONE_NEWUTS
		| CLONE_NEWUSER
		| CLONE_NEWPID
		| CLONE_NEWNS
		/* | CLONE_NEWIPC | CLONE_NEWPID | CLONE_NEWNS | CLONE_NEWNET | CLONE_NEWUSER */ , NULL);
   
	if(container_pid < 0) {
		perror("clone failed");
		return 1;
	}

	pid = container_pid;
	snprintf(path, PATH_MAX_LEN, "/proc/%d/uid_map", pid);
	fd = open(path, O_RDWR);
	if(fd < 0) {
		perror("open /proc/pid/uid_map failed");
		kill(pid, SIGKILL);
		exit(1);
	}
	ret = write(fd, UID_MAP, strlen(UID_MAP));
	if(ret < 0) {
		perror("write /proc/pid/uid_map failed");
		close(fd);
		kill(pid, SIGKILL);
		exit(1);
	}
	close(fd);

	snprintf(path, PATH_MAX_LEN, "/proc/%d/setgroups", pid);
	fd = open(path, O_RDWR);
	if(fd < 0) {
		perror("open /proc/pid/setgroups failed");
		printf("open /proc/%d/setgroups error\n", pid);
		while(1);
		kill(pid, SIGKILL);
		exit(1);
	}
	ret = write(fd, "deny", strlen("deny"));
	if(ret < 0) {
		perror("write /proc/pid/setgroups failed");
		close(fd);
		kill(pid, SIGKILL);
		exit(1);
	}
	close(fd);

	snprintf(path, PATH_MAX_LEN, "/proc/%d/gid_map", pid);
	fd = open(path, O_RDWR);
	if(fd < 0) {
		perror("open /proc/pid/gid_map failed");
		kill(pid, SIGKILL);
		exit(1);
	}
	ret = write(fd, GID_MAP, strlen(GID_MAP));
	if(ret < 0) {
		perror("write /proc/pid/gid_map failed");
		close(fd);
		kill(pid, SIGKILL);
		exit(1);
	}
	close(fd);
	printf("set uid_map gid_map finished\n");

	// 等待容器进程结束
	waitpid(container_pid, NULL, 0);
	return 0;
}
