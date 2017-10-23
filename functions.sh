[ ! -f "${UPV_ROOT}/functions.sh" ] || source "${UPV_ROOT}/functions.sh" || exit 1

generate_ssh_key() {
    local KEY_COMMENT="${1}"; local KEY_FILE="${2}"
    info "Generating ssh key"
    dumpenv KEY_COMMENT KEY_FILE
    ensure_file_not_exists "${KEY_FILE}" "${KEY_FILE}.pub"
    ssh-keygen -t rsa -b 4096 -C "${KEY_COMMENT}" -f "${KEY_FILE}" -N "" -q
}

add_ssh_socks_proxy_authorized_key() {
    local KEY_FILE="${1}"; local OPTS="${2}"; local PORT="${3}"; local HOST="${4}"; local AUTHORIZED_KEYS_FILE="${5}"
    info "Adding ssh proxy authorized key"
    dumpenv KEY_FILE OPTS PORT HOST AUTHORIZED_KEYS_FILE
    PUBKEY=`cat "${KEY_FILE}.pub"`
    AUTHORIZED_KEY='no-agent-forwarding,no-X11-forwarding,command="read a; exit" '"${PUBKEY}"
    echo "${AUTHORIZED_KEY}" | ssh $OPTS -p "${PORT}" "${HOST}" 'cat >> '"${AUTHORIZED_KEYS_FILE}"
}
