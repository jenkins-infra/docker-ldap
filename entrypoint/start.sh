#!/bin/bash
set -e

# shellcheck disable=SC1091
source /entrypoint/functions

is_ssl_certs
configure_slapd
start_slapd
