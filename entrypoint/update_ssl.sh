#!/bin/bash

# Query http endpoint in order to request a new letsencrypt certificate
curl -i "${OPENLDAP_ENDPOINT}"

# Reload certificate
ldapmodify -x \
    -w "${OPENLDAP_CONFIG_ADMIN_PASSWORD}" \
    -D "${OPENLDAP_CONFIG_ADMIN_DN}" \
    -H ldap://localhost \
    -f /etc/openldap/tls.ldif
