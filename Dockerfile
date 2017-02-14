FROM centos:7.1.1503

MAINTAINER Tim Pouyer <tpouyer@us.ibm.com>

ARG ARTIFACT_DOWNLOAD_URL
ARG ARTIFACT_VERSION

COPY artifacts/build.gradle /tmp/
COPY artifacts/*.sh /usr/bin/

RUN yum -y swap fakesystemd systemd && \
    yum -y install which \
                  net-tools \
                  wget \
                  unzip \
                  git \
                  tar \
                  gzip \
                  logrotate \
                  python-setuptools && \
    /usr/bin/easy_install supervisor && \
    wget -q -O - $ARTIFACT_DOWNLOAD_URL | tar zxf - -C /tmp/ && \
    mv /tmp/build.gradle /tmp/ibm-ucd-patterns-install/engine-install/media/ && \
    cd /tmp/ibm-ucd-patterns-install/engine-install && \
    ./install.sh -l -a http://CHANGE_IT:5000/v3 -i CHANGE_IT -b 0.0.0.0 -s No && \
    yum -y erase rabbitmq-server.noarch mariadb-server.x86_64 && \
    yum clean all && \
    rm -rf /tmp/ibm-ucd-patterns-install /tmp/ibm-heat-plugins-install /etc/yum.repos.d/ibm-heat-install.repo /tmp/ibm-ucd-patterns-engine-$ARTIFACT_VERSION.tgz && \
    chmod u+x /usr/bin/engine-tools.sh /usr/bin/configure-os-services.sh

COPY supervisord.conf /usr/etc/supervisord.conf

EXPOSE 8000 8003 8004 5000 35357

CMD ["/usr/bin/supervisord", "-c", "/usr/etc/supervisord.conf"]
