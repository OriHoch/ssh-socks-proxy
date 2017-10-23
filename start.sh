#!/usr/bin/env bash

source functions.sh
source_dotenv
require_params SSH_HOST SSH_B64_KEY SSH_B64_PUBKEY SOCKS_PORT SSH_PORT

info "Starting ssh-socks-proxy"
dumpenv SSH_HOST SOCKS_PORT SSH_PORT
dumpenv_secret SSH_B64_KEY SSH_B64_PUBKEY

TEMPDIR=`mktemp -d`
KEYFILE="${TEMPDIR}/key"

echo "${SSH_B64_KEY}" | base64 -d > "${KEYFILE}"
echo "${SSH_B64_PUBKEY}" | base64 -d > "${KEYFILE}.pub"
chmod 400 "${KEYFILE}"
ssh -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no -p "${SSH_PORT}" -D "0.0.0.0:${SOCKS_PORT}" -C -N -i "${KEYFILE}" "${SSH_HOST}" &
PIDS="${!}"
sleep 2

echo " > Started ssh socks proxy on port ${SOCKS_PORT}"

trap "echo 'caught SIGTERM, attempting graceful shutdown'; graceful_handler \"${PIDS}\" \"${TEMPDIR}\"" SIGTERM;
trap "echo 'caught SIGINT, attempting graceful shutdown'; graceful_handler \"${PIDS}\" \"${TEMPDIR}\"" SIGINT;
while true; do tail -f /dev/null & wait ${!}; done
