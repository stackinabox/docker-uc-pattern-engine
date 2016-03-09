#!/bin/bash
set -e

IFC=$(ifconfig | grep '^[a-z0-9]' | awk '{print $1}' | grep -e ns -e eth0)
IP_ADDRESS=$(ifconfig $IFC | grep 'inet addr' | awk -F : {'print $2'} | awk {'print $1'} | head -n 1)
echo "This node has an IP of " $IP_ADDRESS
#echo "$IP_ADDRESS engine.localdomain" >> /etc/hosts
#hostname engine.$IP_ADDRESS.xip.io
#hostname engine.localdomain

if [ -z "$PUBLIC_HOSTNAME" ]; then  
  PUBLIC_HOSTNAME=boot2docker
fi

echo "$IP_ADDRESS $PUBLIC_HOSTNAME" >> /etc/hosts

if [ -z "$ALLOWED_AUTH_URIS" ]; then
  echo "
    Using default keystone configured for this engine:  

    http://$PUBLIC_HOSTNAME:5000/v2.0

    If you wish to attach to additional clouds, please specify the orchestration 
    endpoint url using:

    \"-e ALLOWED_AUTH_URIS=http://{hostname}:5000/v2.0\" 

    as an option supplied to your docker run command."
fi

env
 
sed -i "s/ENGINE_HOSTNAME/$PUBLIC_HOSTNAME/g" /etc/heat/heat.conf
sed -i "s/\(allowed_auth_uris=\).*\$/\1http:\/\/${PUBLIC_HOSTNAME}:5000\/v2.0,${ALLOWED_AUTH_URIS}/" /etc/heat/heat.conf
 
#chmod u+x /root/post-configure-identity-service.sh
mkdir /root/.qpidd

/usr/bin/supervisord -c /etc/supervisord.conf
