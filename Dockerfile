FROM nuocw/buildpack-deps:centos7
MAINTAINER "TOIDA Yuto" <toida.yuto@b.mbox.nagoya-u.ac.jp>

ENV PHP_IUS=php56
ENV IUS_RELEASE="https://dl.iuscommunity.org/pub/ius/stable/CentOS/7/x86_64/ius-release-1.0-14.ius.centos7.noarch.rpm"

# SSH, Apache and PHP
RUN yum update -y && yum install -y epel-release && yum clean all
RUN rpm -Uvh ${IUS_RELEASE}
RUN yum update -y && yum install -y \
    --exclude=${PHP_IUS}u-xcache* \
    openssh-server \
    httpd \
    ${PHP_IUS}* && yum clean all

RUN yum update -y && yum install -y python-setuptools && yum clean all
RUN easy_install supervisor

# add user "nuocw"
RUN useradd nuocw
USER nuocw
ENV HOME="/home/nuocw"
WORKDIR ${HOME}

# ssh login configuration
USER root
RUN mkdir ~/.ssh
ADD id_ecdsa.pub ${HOME}/.ssh/authorized_keys
RUN chown nuocw. -R ${HOME}/.ssh && chmod 0700 ${HOME}/.ssh && chmod 0600 ${HOME}/.ssh/authorized_keys

# ssh server key generation
RUN ssh-keygen -t rsa -f /etc/ssh/ssh_host_rsa_key -C '' -N ''
RUN ssh-keygen -t ecdsa -f /etc/ssh/ssh_host_ecdsa_key -C '' -N ''
RUN ssh-keygen -t ed25519 -f /etc/ssh/ssh_host_ed25519_key -C '' -N ''

# supervisor configuration
RUN mkdir -p /var/log/supervisor
ADD supervisord.conf ${HOME}/supervisord.conf
RUN echo_supervisord_conf | sed -e "s/nodaemon=false/nodaemon=true /" > /etc/supervisord.conf && cat ${HOME}/supervisord.conf >> /etc/supervisord.conf
RUN rm ${HOME}/supervisord.conf


EXPOSE 80
EXPOSE 443
EXPOSE 22

CMD ["/usr/bin/supervisord"]
