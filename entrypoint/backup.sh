#!/bin/bash

set -e

# shellcheck disable=SC1091
source /entrypoint/functions

: "${OPENLDAP_BACKUP_PATH:?Openldap backup path required}"

is_ssl_certs
configure_slapd
backup
