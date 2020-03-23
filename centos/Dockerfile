FROM centos:7

RUN yum install -y vim net-tools rpm
# change root password
RUN echo "root:root" | chpasswd

RUN yum install -y initscripts

RUN touch /etc/sysconfig/network
RUN echo "GATEWAY=192.168.2.1" >> /etc/sysconfig/network
