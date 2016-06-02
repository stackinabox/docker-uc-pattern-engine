FROM centos:6

MAINTAINER Tim Pouyer <tpouyer@us.ibm.com>

# Pass in the location of the UCD agent install zip 
ARG ARTIFACT_DOWNLOAD_URL 
ARG ARTIFACT_VERSION

# Add startup.sh script and addtional supervisord config
ADD startup.sh /opt/startup.sh
ADD supervisord.conf /etc/supervisor/conf.d/supervisord.conf

ADD post-configure-identity-service.sh /root/post-configure-identity-service.sh

ENV PUBLIC_HOSTNAME=${PUBLIC_HOSTNAME:-$HOSTNAME} \
    ALLOWED_AUTH_URIS=${ALLOWED_AUTH_URIs:-}

EXPOSE 8000
EXPOSE 8003
EXPOSE 8004
EXPOSE 5000
EXPOSE 5672

RUN /usr/bin/yum -y update && \
  /usr/bin/yum -y install wget \
                  unzip \
                  git \
                  tar \
                  gzip \
                  logrotate \
                  python-setuptools \
                  gcc \
                  gcc-c++ \
                  mysql-devel \
                  python-devel && \
  /usr/bin/easy_install supervisor && \
  wget --no-check-certificate https://bootstrap.pypa.io/get-pip.py && \
  python get-pip.py && \
  pip install MySQL-python && \
  wget -O - $ARTIFACT_DOWNLOAD_URL | tar zxf - -C /tmp/ && \
  cd /tmp/ibm-ucd-patterns-install/engine-install && \
  JAVA_HOME=/tmp/ibm-ucd-patterns-install/engine-install/media/engine/java/jre \
  JAVA_OPTS=" -Dlicense.accepted=Y -Dinstall.engine.dependencies.installed=Y \
  -Dinstall.engine.keystone.url=KEYSTONE_URL \
  -Dinstall.engine.public.hostname=ENGINE_HOSTNAME \
  -Dinstall.engine.bind.addr=0.0.0.0" \
  ./gradlew -sSq install && \
  cp /tmp/ibm-ucd-patterns-install/engine-install/media/engine/bin/configure-identity-service.sh /root/configure-identity-service.sh && \
  rm -rf /tmp/ibm-ucd-patterns-install && \
  /usr/bin/yum clean packages

ENTRYPOINT ["/opt/startup.sh"] 
CMD []



