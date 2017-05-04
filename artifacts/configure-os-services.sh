#!/bin/sh
#
# Licensed Materials - Property of IBM Corp.
# IBM UrbanCode Deploy
# (c) Copyright IBM Corporation 2011, 2015. All Rights Reserved.
#
# U.S. Government Users Restricted Rights - Use, duplication or disclosure restricted by
# GSA ADP Schedule Contract with IBM Corp.
#

# hostname -> dns lookup ip address

if [ -f /etc/heat/.init ]; then
  exit 0
fi

# Extract the IP address from ping response of a hostname/IP
PUBLIC_HOSTNAME=$(ping $HOST_PUBLIC_IP_ADDRESS -c 1 | awk -F" |:" '/from/'| grep -oE '[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+')

# Returns true if empty
if [ -z "$PUBLIC_HOSTNAME" ] ; then
  echo "Warning: Cannot obtain the machine's HOST PUBLIC IP ADDRESS, use default hostname: engine."
  PUBLIC_HOSTNAME=engine
fi
echo "Setting PUBLIC_HOSTNAME = $PUBLIC_HOSTNAME"

if [ -z "$IDENTITY_ADMIN_PASSWORD" ]; then
 IDENTITY_ADMIN_PASSWORD="openstack1"
fi

if [ -z "$HEAT_USER_PASSWORD" ]; then
 HEAT_USER_PASSWORD="openstack1"
fi

if [ -z "$DEFAULT_EMAIL_ADDR" ]; then
 DEFAULT_EMAIL_ADDR="undefined@host.com"
fi

if [ -z "$RABBITMQ_HOST" ]; then
  RABBITMQ_HOST="rabbitmq"
fi

if [ -z "$RABBITMQ_PASSWD" ]; then
  RABBITMQ_PASSWD="guest"
fi

if [ -z "$RABBITMQ_USER" ]; then
  RABBITMQ_USER="guest"
fi

if [ -z "$KEYSTONE_DB_HOST" ]; then
  KEYSTONE_DB_HOST="keystonedb"
fi

if [ -z "$KEYSTONE_DB_PASSWD" ]; then
  KEYSTONE_DB_PASSWD="keystone"
fi

if [ -z "$HEAT_DB_HOST" ]; then
  HEAT_DB_HOST="heatdb"
fi

if [ -z "$HEAT_DB_PASSWD" ]; then
  HEAT_DB_PASSWD="heat"
fi

# update heat and keystone conf
openstack-config --set /etc/heat/heat.conf DEFAULT rabbit_host ${RABBITMQ_HOST}
openstack-config --set /etc/heat/heat.conf DEFAULT rabbit_userid ${RABBITMQ_USER}
openstack-config --set /etc/heat/heat.conf DEFAULT rabbit_password ${RABBITMQ_PASSWD}

openstack-config --set /etc/heat/heat.conf DEFAULT heat_metadata_server_url "http://${PUBLIC_HOSTNAME}:8000"
openstack-config --set /etc/heat/heat.conf DEFAULT heat_waitcondition_server_url "http://${PUBLIC_HOSTNAME}:8000/v1/waitcondition"
openstack-config --set /etc/heat/heat.conf DEFAULT heat_watch_server_url "http://${PUBLIC_HOSTNAME}:8003"

openstack-config --set /etc/heat/heat.conf clients_heat url "http://${PUBLIC_HOSTNAME}:8004/v1/%(tenant_id)s"

openstack-config --set /etc/heat/heat.conf database connection "mysql://heat:${HEAT_DB_PASSWD}@${HEAT_DB_HOST}:3306/heat?charset=utf8"
openstack-config --set /etc/keystone/keystone.conf database connection "mysql://keystone:${KEYSTONE_DB_PASSWD}@${KEYSTONE_DB_HOST}:3306/keystone?charset=utf8"

sed -i "s|allowed_auth_uris=.*|allowed_auth_uris=http:\/\/${PUBLIC_HOSTNAME}:5000\/v3,${ALLOWED_AUTH_URIS}|g" /etc/heat/heat.conf

if netstat -ant | grep 5000; then
  echo "Openstack Identity Service is running ..."
  ps -U keystone | tail -n +2 | awk {'print $1'} | xargs --no-run-if-empty kill -9
fi

until mysql -P 3306 -uheat -pheat -h heatdb -e "select 1" >/dev/null ; do
    >&2 echo "heatdb is unavailable - sleeping"
    sleep 1
  done

  >&2 echo "heatdb is up - executing command"

until mysql -P 3306 -ukeystone -pkeystone -h keystonedb -e "select 1" >/dev/null ; do
    >&2 echo "keystonedb is unavailable - sleeping"
    sleep 1
  done

  >&2 echo "keystonedb is up - executing command"

heat-manage db_sync
keystone-manage db_sync

HOME=/root
source $HOME/keystonerc

openstack project create --domain default --description 'Admin Tenant' admin
openstack project create --domain default --description 'Service Tenant' service

openstack user create --domain default --password $IDENTITY_ADMIN_PASSWORD --email $DEFAULT_EMAIL_ADDR admin
openstack user create --domain default --password $HEAT_USER_PASSWORD --email $DEFAULT_EMAIL_ADDR heat

openstack role create admin
openstack role create heat_stack_user
openstack role create heat_stack_owner

openstack role add --project admin --user admin admin
openstack role add --project service --user admin admin
openstack role add --project service --user heat admin

openstack service create --name keystone --description "OpenStack Identity Service" identity
openstack service create --name heat --description "OpenStack Orchestration Service" orchestration

KEYSTONE_UUID=$(openstack service list | grep identity | cut -d " " -f 2 | head -n 1)
if [ -z "$KEYSTONE_UUID" ]; then
  echo "ERROR: Problem registering Openstack Identity Service. Please check your configuration and make verify required updates after installation completes."
else
  echo "Found Keystone Services: $KEYSTONE_UUID"
  openstack endpoint create --region RegionOne identity admin http://$PUBLIC_HOSTNAME:35357/v2.0
  openstack endpoint create --region RegionOne identity public http://$PUBLIC_HOSTNAME:5000/v2.0
  openstack endpoint create --region RegionOne identity internal http://$PUBLIC_HOSTNAME:5000/v2.0
  openstack endpoint create --region RegionOne identity admin http://$PUBLIC_HOSTNAME:35357/v3
  openstack endpoint create --region RegionOne identity public http://$PUBLIC_HOSTNAME:5000/v3
  openstack endpoint create --region RegionOne identity internal http://$PUBLIC_HOSTNAME:5000/v3
fi
HEAT_UUID=$(openstack service list | grep orchestration | cut -d " " -f 2 | head -n 1)
if [ -z "$HEAT_UUID" ]; then
  echo "ERROR: Problem registering Openstack Orchestration Service. Please check your configuration and make verify required updates after installation completes."
else
  echo "Found Orchestration Services: $HEAT_UUID"
  openstack endpoint create --region RegionOne orchestration admin "http://$PUBLIC_HOSTNAME:8004/v1/%(tenant_id)s"
  openstack endpoint create --region RegionOne orchestration public "http://$PUBLIC_HOSTNAME:8004/v1/%(tenant_id)s"
  openstack endpoint create --region RegionOne orchestration internal "http://$PUBLIC_HOSTNAME:8004/v1/%(tenant_id)s"
fi

#restart heat services
ps -U heat | tail -n +2 | awk {'print $1'} | xargs --no-run-if-empty kill -9
sed -i "s|CHANGE_IT|$PUBLIC_HOSTNAME|g" /root/clientrc
touch /etc/heat/.init
echo "Done."
echo "--------------------------------------------------------------------------------"
