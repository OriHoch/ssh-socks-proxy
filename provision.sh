#!/usr/bin/env bash

source functions.sh
source_dotenv
read_params SSH_HOST KEY_COMMENT
SSH_PORT="${SSH_PORT:-22}"
AUTHORIZED_KEYS="${AUTHORIZED_KEYS:-.ssh/authorized_keys}"
SOCKS_PORT="${SOCKS_PORT:-8123}"

TEMPDIR=`mktemp -d`
KEY_FILE="${TEMPDIR}/key"

info "Provisioning ssh-socks-proxy"
dumpenv KEY_COMMENT KEY_FILE SSH_OPTS SSH_PORT SSH_HOST AUTHORIZED_KEYS SOCKS_PORT

! generate_ssh_key "${KEY_COMMENT}" "${KEY_FILE}" && bash_on_error && exit 1
! add_ssh_socks_proxy_authorized_key "${KEY_FILE}" "${SSH_OPTS}" \
                                     "${SSH_PORT}" "${SSH_HOST}" "${AUTHORIZED_KEYS}" &&\
                                      bash_on_error && exit 1
dotenv_set SSH_HOST "${SSH_HOST}"
dotenv_set SSH_PORT "${SSH_PORT}"
dotenv_set AUTHORIZED_KEYS "${AUTHORIZED_KEYS}"
dotenv_set SSH_B64_KEY `cat ${KEY_FILE} | base64 -w0`
dotenv_set SSH_B64_PUBKEY `cat ${KEY_FILE}.pub | base64 -w0`
dotenv_set SOCKS_PORT "${SOCKS_PORT}"
dotenv_set KEY_COMMENT "${KEY_COMMENT}"

success "
    Provisioned ssh-socks-proxy
    You can now build / run the docker image:
    -- docker build -t ssh-socks-proxy .
    -- docker rm --force ssh-socks-proxy
    -- docker run -d --rm --name ssh-socks-proxy -p "${SOCKS_PORT}:${SOCKS_PORT}" --env-file .env ssh-socks-proxy
    Test it:
    -- curl http://httpbin.org/ip
    -- curl --socks5-hostname localhost:${SOCKS_PORT} http://httpbin.org/ip
"
