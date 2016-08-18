#!/bin/sh
#
# Licensed Materials - Property of IBM Corp.
# IBM UrbanCode Deploy
# (c) Copyright IBM Corporation 2011, 2015. All Rights Reserved.
#
# U.S. Government Users Restricted Rights - Use, duplication or disclosure restricted by
# GSA ADP Schedule Contract with IBM Corp.
#

if [ -z "$MYSQL_ROOT_PASSWORD" ]; then
  MYSQL_ROOT_PASSWORD=passw0rd
fi

if [ -z "$MYSQL_USER" ]; then
  MYSQL_USER=root
fi

echo "-------------------------------------------------------------------"
echo "Creating Keystone database"

if [ $(mysql -N -s -u$MYSQL_USER -p$MYSQL_ROOT_PASSWORD -e \
    "select count(*) from information_schema.tables where \
        table_schema='keystone' and table_name='region';") -eq 1 ]; then
    keystone-manage db_sync 2> /var/log/keystone/keystone_migration.log
else
    keystone-manage db_sync; keystone-manage pki_setup --keystone-user keystone --keystone-group keystone
fi
echo "-------------------------------------------------------------------"
echo "Keystone database installation finished"
