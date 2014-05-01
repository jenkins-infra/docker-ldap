#!/bin/bash -ex
# this script runs inside Docker to run slapd

# purge existing config
CONFIG=/etc/ldap/slapd.d
rm -rf $CONFIG
mkdir $CONFIG

# import config
slapadd -F $CONFIG -n 0 -l /etc/ldap/config.ldif

# run OpenLDAP in the foreground
exec /usr/sbin/slapd -d2
