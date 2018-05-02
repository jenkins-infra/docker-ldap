#!/bin/bash
set -e

: "${OPENLDAP_RESTORE_FILE:=$OPENLDAP_BACKUP_FILE}"

: "${OPENLDAP_BACKUP_PATH:?Openldap backup path required}"
: "${OPENLDAP_ADMIN_PASSWORD:?Openldap Admin dn password required}"
: "${OPENLDAP_ADMIN_DN:?Openldap admin dn required}"

if [ ! -f "${OPENLDAP_BACKUP_PATH}/${OPENLDAP_RESTORE_FILE}" ]
then
    exit "${OPENLDAP_BACKUP_PATH}/${OPENLDAP_RESTORE_FILE} not found"
fi

echo "Restore ${OPENLDAP_BACKUP_PATH}/${OPENLDAP_RESTORE_FILE}"

if [[ "${OPENLDAP_RESTORE_FILE}" =~ .*\.gz$ ]]
then
    # Require slapd to be stopped
    # su ldap -s /bin/sh -c "gunzip -c \"${OPENLDAP_BACKUP_PATH}/${OPENLDAP_RESTORE_FILE}\" | slapadd -f /etc/ldap/slapd.conf"
    su openldap -s /bin/sh -c "gunzip -c \"${OPENLDAP_BACKUP_PATH}/${OPENLDAP_RESTORE_FILE}\" | ldapmodify -H ldap:/// -x -w \"${OPENLDAP_ADMIN_PASSWORD}\" -D \"${OPENLDAP_ADMIN_DN}\" -a -c"

elif [[ $OPENLDAP_RESTORE_FILE =~ .*\.ldif$ ]]
then
    # Require slapd to be stopped
    #su ldap -s /bin/sh -c "slapadd -f /etc/ldap/slapd.conf -l \"${OPENLDAP_BACKUP_PATH}/${OPENLDAP_RESTORE_FILE}\""
    su openldap -s /bin/sh -c "ldapmodify -H ldap:/// -x -w \"${OPENLDAP_ADMIN_PASSWORD}\" -D \"${OPENLDAP_ADMIN_DN}\" -a -c -f \"${OPENLDAP_BACKUP_PATH}/${OPENLDAP_RESTORE_FILE}\""
else
    echo "Extension not recognised, must be either .gz or .ldif"
fi
