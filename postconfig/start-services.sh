#!/bin/sh
#
# Licensed Materials - Property of IBM Corp.
# IBM UrbanCode Deploy
# (c) Copyright IBM Corporation 2011, 2015. All Rights Reserved.
#
# U.S. Government Users Restricted Rights - Use, duplication or disclosure restricted by
# GSA ADP Schedule Contract with IBM Corp.
#

echo "Starting and enabling OpenStack services ..."
systemctl start  mariadb.service
systemctl enable  mariadb.service
systemctl start  rabbitmq-server.service
systemctl enable  rabbitmq-server.service
systemctl start  openstack-heat-engine.service
systemctl enable  openstack-heat-engine.service
systemctl start  openstack-heat-api.service
systemctl enable  openstack-heat-api.service
systemctl start  openstack-heat-api-cfn.service
systemctl enable  openstack-heat-api-cfn.service
systemctl start  openstack-heat-api-cloudwatch.service
systemctl enable  openstack-heat-api-cloudwatch.service
systemctl start  openstack-keystone.service
systemctl enable  openstack-keystone.service
echo "All OpenStack services started and enabled."
systemctl disable init-heat.service
