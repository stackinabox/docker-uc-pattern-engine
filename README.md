### docker-uc-pattern-engine

builds a docker image with UrbanCode Deploy with Patterns HEAT engine (and plugin extensions)

To run:

 - git clone stackinabox/docker-uc-pattern-engine.git

 - Build the image:

 ````
docker build --rm -t stackinabox/urbancode-patterns-engine:$ARTIFACT_VERSION --build-arg ARTIFACT_DOWNLOAD_URL=$ARTIFACT_DOWNLOAD_URL .
 ````

  - Now your ready to run the patterns-engine container. The command below supplies the container with a couple of ENV properties
  	- PUBLIC_HOSTNAME: a resolveable dns name for this container, you can add an entry to your /etc/hosts file for a quick solution
  	- ALLOWED_AUTH_URIS: This value is used by the embedded HEAT engine to determine which OpenStack Keystone endpoints will be allowed to operate this engine
   - These are in a file "envvars.txt" and passed in as a volume to /root/envvars.txt at run time 

  ````
  docker run -d --privileged=true -v ./envvars.txt:/root/envvars.txt -v /sys/fs/cgroup:/sys/fs/cgroup:ro --name urbancode_patterns_engine -p 8000:8000 -p 8003:8003 -p 8004:8004 stackinabox/urbancode-patterns-engine:$ARTIFACT_VERSION 
  ````
