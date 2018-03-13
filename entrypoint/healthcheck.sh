#!/bin/bash

: "${OPENLDAP_HEALTHCHECK_QUERY:=cn=admins,ou=groups,dc=jenkins-ci,dc=org}"

echo "Test ldap://"
ldapsearch \
    -H ldap://127.0.0.1 \
    -LLL \
    -x \
    -w "${OPENLDAP_ADMIN_PASSWORD}" \
    -D "${OPENLDAP_ADMIN_DN}" \
    -b "${OPENLDAP_HEALTHCHECK_QUERY}"
