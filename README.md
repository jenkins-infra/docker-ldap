This container runs OpenLDAP that hosts user accounts on Jenkins.
It expects the following volumes to be mounted from outside:

  `/var/lib/ldap` would have to be mounted in. This is where the database will be.

  `/etc/ldap/config.ldif` has to be mounted into the container that hosts the configuration
  This defines the configuration file in slapcat dump format
