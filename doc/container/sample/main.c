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

#define STACK_SIZE (1024 * 1024)
#define PATH_MAX_LEN 20

static char container_stack[STACK_SIZE];
char* const container_args[] = {
	"/bin/bash",
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
		exit(1);
	}
	ret = write(fd, "0          0 4294967295\n", strlen("0          0 4294967295\n"));
	if(ret < 0) {
		perror("write /proc/pid/uid_map failed");
		close(fd);
		exit(1);
	}
	close(fd);

	snprintf(path, PATH_MAX_LEN, "/proc/%d/gid_map", pid);
	fd = open(path, O_RDWR);
	if(fd < 0) {
		perror("open /proc/pid/gid_map failed");
		exit(1);
	}
	ret = write(fd, "0          0 4294967295\n", strlen("0          0 4294967295\n"));
	if(ret < 0) {
		perror("write /proc/pid/gid_map failed");
		close(fd);
		exit(1);
	}
	close(fd);
	printf("set uid_map gid_map finished\n");

	// 等待容器进程结束
	waitpid(container_pid, NULL, 0);
	return 0;
}
