FROM stackinabox/supervisord:3.2.2

ADD supervisord.conf /etc/supervisord.conf
ADD startup.sh /opt/startup.sh

ADD artifacts/ibm-ucd-patterns-install /tmp/ibm-ucd-patterns-install


RUN /usr/bin/yum -y update && \
  /usr/bin/yum -y install tar gzip logrotate && \
  yum clean packages
  
RUN yum -y groupinstall "Development tools"

RUN yum install -y gcc gcc-c++ kernel-devel mysql-devel python-devel zlib-devel bzip2-devel openssl-devel ncurses-devel sqlite-devel readline-devel tk-devel

RUN cd /opt && \
  wget --no-check-certificate https://www.python.org/ftp/python/2.7.10/Python-2.7.10.tgz && \
  tar xzf Python-2.7.10.tgz && \
  cd Python-2.7.10 && \
  ./configure --prefix=/usr/local && \
  make && \
  make install

RUN cd /opt && \
  wget --no-check-certificate https://bootstrap.pypa.io/get-pip.py && \
  python get-pip.py && \
  pip install MySQL-python

EXPOSE 8000
EXPOSE 8003
EXPOSE 8004
EXPOSE 5000
EXPOSE 5672

EXPOSE 22

ENV PUBLIC_HOSTNAME ${PUBLIC_HOSTNAME:-$HOSTNAME}

RUN cd /tmp/ibm-ucd-patterns-install/engine-install && \
JAVA_HOME=/tmp/ibm-ucd-patterns-install/engine-install/media/engine/java/jre \
JAVA_OPTS=" -Dlicense.accepted=Y -Dinstall.engine.dependencies.installed=Y \
-Dinstall.engine.keystone.url=KEYSTONE_URL \
-Dinstall.engine.public.hostname=ENGINE_HOSTNAME  \
-Dinstall.engine.bind.addr=0.0.0.0" \
./gradlew -sSq install && \
rm -rf /tmp/ibm-ucd-patterns-install/engine-install

#COPY artifacts/docker/docker /usr/lib/heat/docker
#RUN pip install -r /usr/lib/heat/docker/requirements.txt

COPY artifacts/ibm-ucd-patterns-install/engine-install/media/engine/bin/configure-identity-service.sh /root/configure-identity-service.sh
COPY post-configure-identity-service.sh /root/post-configure-identity-service.sh 

CMD ["/opt/startup.sh"] 

# docker build -t stackinabox/urbancode-patterns-engine:%version% .
# docker run -d --name test-engine -p 18000:8000 -p 18003:8003 -p 18004:8004 --link test-database:database stackinabox/urbancode-patterns-engine 
# docker stop test-designer && docker rm test-designer
# docker run -d --name test-designer -p 10080:9080 -p 10443:9443 -p 10022:22 -v /Users/mdelder/Downloads:/opt/ibm-ucd-patterns/logs --link test-database:database stackinabox/urbancode-patterns-webdesigner 

