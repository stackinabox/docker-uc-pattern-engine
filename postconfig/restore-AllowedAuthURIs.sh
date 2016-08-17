#!/bin/sh
#
# Licensed Materials - Property of IBM Corp.
# IBM UrbanCode Deploy
# (c) Copyright IBM Corporation 2011, 2015. All Rights Reserved.
#
# U.S. Government Users Restricted Rights - Use, duplication or disclosure restricted by
# GSA ADP Schedule Contract with IBM Corp.
#

echo "Restoring Heat Engine's allowed_auth_uris"
old_allowed_auth_uris=`cat $1| grep "^allowed_auth_uris" | awk 'NR==1{print $1}' | cut -d'=' -f2`
new_allowed_auth_uris=`cat /etc/heat/heat.conf| grep "^allowed_auth_uris" | awk 'NR==1{print $1}' | cut -d'=' -f2`

echo "previous heat.conf allowed_auth_uris' value = $old_allowed_auth_uris"
echo "current heat.conf allowed_auth_uris' value = $new_allowed_auth_uris"


if [ ! -z "$old_allowed_auth_uris" ] ; then
	if [ "$old_allowed_auth_uris" != "$new_allowed_auth_uris" ] ; then
		sed -i "s|^allowed_auth_uris=.*|allowed_auth_uris=$old_allowed_auth_uris|g" /etc/heat/heat.conf
		echo "restored..."
	else
		echo "skipped..."
	fi
else
	echo "Cannot restore Heat Engine's allowed_auth_uris."
fi