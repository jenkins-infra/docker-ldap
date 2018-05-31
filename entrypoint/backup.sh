#!/bin/bash

set -e

# shellcheck disable=SC1091
source /entrypoint/functions

: "${OPENLDAP_BACKUP_PATH:?Openldap backup path required}"

backup && clean_backup
