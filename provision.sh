#!/usr/bin/env bash

source ./functions.sh
source_dotenv
read_params SSH_HOST KEY_COMMENT

info "Provisioning ssh-socks-proxy"
dumpenv KEY_COMMENT KEY_FILE PROVISION_SSH_OPTS SSH_PORT SSH_HOST AUTHORIZED_KEYS SOCKS_PORT

SSH_PORT="${SSH_PORT:-22}"
AUTHORIZED_KEYS="${AUTHORIZED_KEYS:-.ssh/authorized_keys}"
dumpenv SSH_PORT AUTHORIZED_KEYS

TEMPDIR=`mktemp -d`
KEY_FILE="${TEMPDIR}/key"

generate_ssh_key "${KEY_COMMENT}" "${KEY_FILE}" &&\
add_ssh_socks_proxy_authorized_key "${KEY_FILE}" "${PROVISION_SSH_OPTS}" \
                                   "${SSH_PORT}" "${SSH_HOST}" "${AUTHORIZED_KEYS}" &&\
echo_trim "
    SSH_HOST=${SSH_HOST}
    SSH_PORT=${SSH_PORT}
    AUTHORIZED_KEYS=${AUTHORIZED_KEYS}
    SSH_B64_KEY=`cat ${KEY_FILE} | base64 -w0`
    SSH_B64_PUBKEY=`cat ${KEY_FILE}.pub | base64 -w0`
    SOCKS_PORT=${SOCKS_PORT:-8123}
    KEY_COMMENT=${KEY_COMMENT}
    PROVISION_SSH_OPTS=${PROVISION_SSH_OPTS}
" > .env
