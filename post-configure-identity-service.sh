#!/bin/sh

if netstat -ant | grep 5000; then 
  echo "Openstack Identity Service is running ..."
else
  echo "Hoping you didn't forget to start Keystone ..."
  sleep 15 
fi

if netstat -ant | grep 5000; then 
  echo "Post install configuration of keystone running..."
  

  USER_DIR=/root

  sed -i "s/KEYSTONE_URL/http:\/\/${PUBLIC_HOSTNAME}:35357\/v2.0/" $USER_DIR/keystonerc
  sed -i "s/ENGINE_HOSTNAME/${PUBLIC_HOSTNAME}/g" $USER_DIR/keystonerc
  cat $USER_DIR/keystonerc

  . $USER_DIR/keystonerc

  keystone endpoint-list

  for id in `keystone endpoint-list | grep http | cut -d " " -f 2`; do 
    echo "Found endpoint with id: $id"; 
    echo "Removing endpoint with id: $id"; 
    keystone endpoint-delete $id; 
  done

  keystone service-list

  for id in `keystone service-list | grep http | cut -d " " -f 2`; do 
    echo "Found service with id: $id"; 
    echo "Removing service with id: $id"; 
    keystone service-delete $id; 
  done

  /root/configure-identity-service.sh

  echo "
    Use the following settings to connect OpenStack:
  "
  sed -i "s/KEYSTONE_URL/http:\/\/${PUBLIC_HOSTNAME}:35357\/v2.0/g" $USER_DIR/clientrc
  sed -i "s/ENGINE_HOSTNAME/${PUBLIC_HOSTNAME}/g" $USER_DIR/clientrc

  cat $USER_DIR/clientrc

  
else
  echo "ERROR: Problem configurating keystone! The service was not running and no commands were executed."
fi

exit 0