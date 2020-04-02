FROM centos:7

RUN yum install -y vim net-tools rpm dhclient
# change root password
RUN echo "root:root" | chpasswd

#RUN yum install -y initscripts
#RUN touch /etc/sysconfig/network

# config the net with dhclient
RUN chmod 755 /etc/rc.d/rc.local
RUN echo "dhclient eth0" >> /etc/rc.d/rc.local

# ssh
RUN yum install -y openssh-server
