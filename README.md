# OpenLdap
OpenLdap docker image used for Jenkins Infrastructure Project
This project defines two docker images, one that run openldap and a second one that run a cron daemon who periodically backup the database

### Certificate
This openldap container require valid SSL certificate located in /etc/ldap/ssl where each filename is one of the following variable.

* OPENLDAP_SSL_KEY
* OPENLDAP_SSL_CRT
* OPENLDAP_SSL_CA

## Scripts:
This docker image contains various scripts to run different actions.

Create backup:
`/entrypoint/backup`

HealtchCheck:
`/entrypoint/healthcheck`

Restore backup:
`/entrypoint/restore`

Start slapd:
`/entrypoint/start`

## Configuration
This docker image can be configured with some env variable.

##### OPENLDAP_ADMIN_DN
Define openldap admin DN

Default: 'cn=admin,dc=jenkins-ci,dc=org'

##### OPENLDAP_ADMIN_PASSWORD
Define openldap admin password

Default: 's3cr3t'

##### OPENLDAP_BACKUP_PATH
Define openldap backup directory

Default: '/backup'

##### OPENLDAP_BACKUP_FILE
Define openldap backup file name.
Filename must end with ldiff

Default: 'backup.latest.ldif'

##### OPENLDAP_DATABASE
Define slapd database name

Default: 'dc=jenkins-ci,dc=org'

##### OPENLDAP_DEBUG_LEVEL
Define slapd loglevel

Default: '256'

##### OPENLDAP_HEALTHCHECK_QUERY
Define the ldap query  used for healtcheck

Default to: 'cn=admins,ou=groups,dc=jenkins-ci,dc=org'

##### OPENLDAP_RESTORE_FILE
Define backup file to restore.

Default: OPENLDAP_BACKUP_FILE

##### OPENLDAP_SSL_KEY
Define ssl private key file name.
This file must be located in /etc/ldap/ssl

Default: 'privkey.key'

##### OPENLDAP_SSL_CRT
Define ssl certificate file name.
This file must be located in /etc/ldap/ssl

Default: 'cert.pem'

##### OPENLDAP_SSL_CA
Define ca certificate file name.
This file must be located in /etc/ldap/ssl

Default: 'ca.pem'


## Links
[Slapd-config](https://www.openldap.org/doc/admin24/runningslapd.html)
