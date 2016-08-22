FROM centos/systemd

MAINTAINER Tim Pouyer <tpouyer@us.ibm.com>
MAINTAINER Sudhakar Frederick <sudhakar@au1.ibm.com>

ARG ARTIFACT_DOWNLOAD_URL

ADD postconfig /opt/postconfig

ENV PUBLIC_HOSTNAME=${PUBLIC_HOSTNAME:-$HOSTNAME} \
    ALLOWED_AUTH_URIS=${ALLOWED_AUTH_URIs:-}

EXPOSE 8000
EXPOSE 8003
EXPOSE 8004
EXPOSE 5000
EXPOSE 5672

RUN /usr/bin/yum -y update && \
  /usr/bin/yum -y install which \
                  wget \
                  unzip \
                  git \
                  tar \
                  gzip \
                  logrotate \
                  net-tools \
                  python-setuptools \
                  gcc \
                  gcc-c++ && \
  wget --no-check-certificate https://bootstrap.pypa.io/get-pip.py && \
  python get-pip.py && \
  pip install --upgrade pip && \
  chmod +x /opt/postconfig/*.sh

#use this when testing local
#ADD ibm-ucd-patterns-engine-6.2.1.2.801498.tgz /tmp/

RUN  wget -O - $ARTIFACT_DOWNLOAD_URL | tar zxf - -C /tmp/ && \
  rm -f /tmp/ibm-ucd-patterns-install/engine-install/media/build.gradle && \
  cp /opt/postconfig/build.gradle /tmp/ibm-ucd-patterns-install/engine-install/media/build.gradle && \
  cd /tmp/ibm-ucd-patterns-install/engine-install && \
  JAVA_HOME=/tmp/ibm-ucd-patterns-install/engine-install/media/engine/java/jre \
  JAVA_OPTS=" -Dlicense.accepted=Y -Dinstall.engine.dependencies.installed=Y \
  -Dinstall.engine.start.services=No \
  -Dinstall.engine.keystone.url=KEYSTONE_URL \
  -Dinstall.engine.public.hostname=ENGINE_HOSTNAME \
  -Dinstall.engine.bind.addr=0.0.0.0" \
  ./gradlew -sSq configure installPatternServices configureMySQLPythonDependencies installIdentityServices configureIdentityService  && \
  rm -rf /tmp/ibm-ucd-patterns-install && \
  /usr/bin/yum clean packages && \
  cp /opt/postconfig/init-heat.service /etc/systemd/system/init-heat.service && \
  systemctl enable init-heat && \
  systemctl enable mariadb && \
  systemctl enable rabbitmq-server

VOLUME ["/root/envvars.txt"]
CMD ["/usr/sbin/init"]
