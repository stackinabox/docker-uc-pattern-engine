### docker-uc-pattern-engine

builds a docker image with UrbanCode Deploy with Patterns HEAT engine (and plugin extensions)

To run:

 - git clone stackinabox/docker-supervisord and build it follwing the README.md in the repo

 - git clone stackinabox/docker-uc-pattern-engine.git

 - Download UCD with Patterns HEAT engine installer zip and extract it into 'artifacts' folder
   You are on your own for finding this since it's a licensed product

 - Build the image:

 ````
    docker build -t stackinabox/urbancode-patterns-engine:%version% .
 ````

  - Now your ready to run the patterns-engine container. The command below supplies the container with a couple of ENV properties
  	- PUBLIC_HOSTNAME: a resolveable dns name for this container, you can add an entry to your /etc/hosts file for a quick solution
  	- ALLOWED_AUTH_URIS: This value is used by the embedded HEAT engine to determine which OpenStack Keystone endpoints will be allowed to operate this engine

  ````
     docker run -d --name urbancode_patterns_engine -e PUBLIC_HOSTNAME=docker -e ALLOWED_AUTH_URIS=http://192.168.27.100:5000/v2.0 -p 8000:8000 -p 8003:8003 -p 8004:8004 stackinabox/urbancode-patterns-engine:%version%
  ````