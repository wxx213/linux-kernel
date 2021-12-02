FROM centos:7

# replace with aliyun repo mirror
# if you don't need, just remove it
RUN yum install -y sudo wget
RUN cd /etc/yum.repos.d  && sudo mv CentOS-Base.repo CentOS-Base.repo.bak && \
	sudo wget -O CentOS-Base.repo http://mirrors.aliyun.com/repo/Centos-7.repo && yum clean all && \
	yum clean all && yum makecache


# for newer gcc
RUN yum install -y centos-release-scl
RUN yum install -y devtoolset-7

# for kernel build
RUN yum install -y make gcc elfutils-libelf-devel bc
# for centos-4.18 kernel build
RUN yum install -y bison flex openssl-devel openssl

# for qemu build
RUN yum install -y gtk2-devel

# for qemu runtime
# RUN yum install -y libX11 gtk2

# for busybox build
RUN yum install -y glibc-static

# for kexec build
RUN yum install -y autoconf

# for make_ext4fs runtime
RUN yum install -y pcre && ln -s /lib64/libpcre.so.1 /lib64/libpcre.so.3
