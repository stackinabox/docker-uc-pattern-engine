#!/bin/sh
#
# Licensed Materials - Property of IBM Corp.
# IBM UrbanCode Deploy
# (c) Copyright IBM Corporation 2011, 2015. All Rights Reserved.
#
# U.S. Government Users Restricted Rights - Use, duplication or disclosure restricted by
# GSA ADP Schedule Contract with IBM Corp.
#

WORKING_DIR="${BASH_SOURCE%/*}"
cd $WORKING_DIR

if [ -z "$OPENSTACK_VERSION" ]; then
 OPENSTACK_VERSION="kilo"
fi

echo "--------------------------------------------------------------------------------"
echo "Starting MariaDB database..."
systemctl start  mariadb.service
echo "Done."
echo "--------------------------------------------------------------------------------"
if [ -z "$MYSQL_ROOT_PASSWORD" ]; then
  MYSQL_ROOT_PASSWORD=passw0rd
fi
echo "Updating MariaDB root user password..."
/usr/bin/mysqladmin -u root password "$MYSQL_ROOT_PASSWORD"
echo "Done."
echo "--------------------------------------------------------------------------------"
if [ -z "$HEAT_USER_PASSWORD" ]; then
  HEAT_USER_PASSWORD=heat
fi
echo "Configuring heat database tables.."
$WORKING_DIR/configure-mysqldb.sh -R "$MYSQL_ROOT_PASSWORD" -D heat -U heat -P "$HEAT_USER_PASSWORD"
echo "Done."
echo "--------------------------------------------------------------------------------"
if [ -z "$KEYSTONE_USER_PASSWORD" ]; then
  KEYSTONE_USER_PASSWORD=keystone
fi
echo "Configuring keystone database tables.."
$WORKING_DIR/configure-mysqldb.sh -R "$MYSQL_ROOT_PASSWORD" -D keystone -U keystone -P "$KEYSTONE_USER_PASSWORD"
echo "Done."
echo "--------------------------------------------------------------------------------"
echo "Starting AMQP server..."
if [ -z "$AMQP_USER" ]; then
  AMQP_USER=guest
fi
if [ -z "$AMQP_PASSWORD" ]; then
  AMQP_PASSWORD=guest
fi

if [  "$OPENSTACK_VERSION" == "juno" -o "$OPENSTACK_VERSION" == "kilo" ]; then
    systemctl start  rabbitmq-server.service
    if rabbitmqctl add_user $AMQP_USER $AMQP_PASSWORD ; then
      echo "Added user $AMQP_USER to RabbitMQ"
    else
      rabbitmqctl change_password $AMQP_USER $AMQP_PASSWORD
    fi
else
    chown qpidd:qpidd /var/lib/qpidd/qpidd.sasldb
    echo "$AMQP_PASSWORD" | saslpasswd2 -f /var/lib/qpidd/qpidd.sasldb -u QPID "$AMQP_USER"
    systemctl start  qpidd.service
fi
echo "Done."
echo "--------------------------------------------------------------------------------"
