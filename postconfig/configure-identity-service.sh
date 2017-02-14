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
if [ -n "$1" ]; then
  PUBLIC_HOSTNAME=$1
elif command -v host; then
  PUBLIC_HOSTNAME=$(host -TtA $(hostname -s) | grep "has address"|awk '{print $1}')
fi

if [ -z "$PUBLIC_HOSTNAME" ]; then
  PUBLIC_HOSTNAME=$(hostname -s)
fi

if [ -z "$IDENTITY_ADMIN_PASSWORD" ]; then
 IDENTITY_ADMIN_PASSWORD="openstack1"
fi

if [ -z "$HEAT_USER_PASSWORD" ]; then
 HEAT_USER_PASSWORD="openstack1"
fi

if [ -z "$DEFAULT_EMAIL_ADDR" ]; then
 DEFAULT_EMAIL_ADDR="undefined@host.com"
fi

SERVICE_STARTED=0
if systemctl status  openstack-keystone.service; then
  echo "Openstack Identity Service is already running. Updating configuration..."
else
  echo "Starting Openstack Identity Service to update configuration..."
  systemctl start  openstack-keystone.service
  # Wait for service to startup
  sleep 10
  SERVICE_STARTED=1
 fi

. $HOME/keystonerc
echo "--------------------------------------------------------------------------------"

if [ $(mysql -N -s -u$MYSQL_USER -p$MYSQL_ROOT_PASSWORD -e \
    "select count(*) from information_schema.tables where \
        table_schema='keystone' and table_name='region';") -eq 1 ]; then
    keystone-manage db_sync 2> /var/log/keystone/keystone_migration.log
else
    keystone-manage db_sync; keystone-manage pki_setup --keystone-user keystone --keystone-group keystone
fi

echo "--------------------------------------------------------------------------------"

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
  openstack endpoint create --region RegionOne identity admin http://$PUBLIC_HOSTNAME/identity_v2_admin
  openstack endpoint create --region RegionOne identity public http://$PUBLIC_HOSTNAME/identity
  openstack endpoint create --region RegionOne identity internal http://$PUBLIC_HOSTNAME/identity
  openstack endpoint create --region RegionOne identity admin http://$PUBLIC_HOSTNAME/identity_v3_admin
  openstack endpoint create --region RegionOne identity public http://$PUBLIC_HOSTNAME/identity/v3
  openstack endpoint create --region RegionOne identity internal http://$PUBLIC_HOSTNAME/identity/v3
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

echo "Done."

echo "--------------------------------------------------------------------------------"
