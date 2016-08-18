#!/bin/sh
#
# Licensed Materials - Property of IBM Corp.
# IBM UrbanCode Deploy
# (c) Copyright IBM Corporation 2011, 2015. All Rights Reserved.
#
# U.S. Government Users Restricted Rights - Use, duplication or disclosure restricted by
# GSA ADP Schedule Contract with IBM Corp.
#


while getopts 'R:D:U:P:' opt; do
  case $opt in
    R)
    MYSQL_ROOT_PASSWORD=$OPTARG
    ;;
    D)
    MYSQL_DATABASE=$OPTARG
    ;;
    U)
    MYSQL_USER=$OPTARG
    ;;
    P)
    MYSQL_PASSWORD=$OPTARG
    ;;
  esac
done


echo "--------------------------------------------------------------------------------"
echo "Creating MariaDB database..."

TEMP_FILE='/tmp/create-heat-db.sql'
echo "
CREATE USER '$MYSQL_USER'@'localhost' IDENTIFIED BY '$MYSQL_PASSWORD';
CREATE DATABASE $MYSQL_DATABASE;
GRANT ALL ON $MYSQL_DATABASE.* TO '$MYSQL_USER'@'%' IDENTIFIED BY '$MYSQL_PASSWORD' WITH GRANT OPTION;
" > "$TEMP_FILE"

mysql -u root -p$MYSQL_ROOT_PASSWORD < "$TEMP_FILE"
rm "$TEMP_FILE"
echo "Done."

echo "You may test the connection using: $ mysql -u $MYSQL_USER -p$MYSQL_PASSWORD -D $MYSQL_DATABASE"
echo "--------------------------------------------------------------------------------"
