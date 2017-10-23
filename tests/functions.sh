[ ! -f "${UPV_ROOT}/functions.sh" ] || source "${UPV_ROOT}/functions.sh" || exit 1
[ ! -f "${UPV_WORKSPACE}/functions.sh" ] || source "${UPV_WORKSPACE}/functions.sh" || exit1

authorize_ssh_key_to_docker_ssh_server() {
    local KEY_FILE="${1}"
    local DOCKER_SSH_SERVER_NAME="${2}"
    echo "Authorizing ssh key to ssh into docker ssh-server container"
    dumpenv KEY_FILE DOCKER_SSH_SERVER_NAME
    cat "${KEY_FILE}.pub" | docker exec -i "${DOCKER_SSH_SERVER_NAME}" /bin/bash -c "cat >> /root/.ssh/authorized_keys"
}

provision_test_environment() {
    info "Provisioning test environment"
    SSH_IDENTITY_FILE="`pwd`/test-host.key"
    HOST_KEY_COMMENT="test host"
    upv_dotenv_set . KEY_COMMENT "test proxy key"
    upv_dotenv_set . SSH_OPTS "-o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no -i ${SSH_IDENTITY_FILE}"
    upv_dotenv_set . SSH_HOST "root@localhost"
    upv_dotenv_set . SSH_PORT "2222"
    upv_dotenv_set . AUTHORIZED_KEYS "/root/.ssh/authorized_keys"
    dumpenv KEY_COMMENT SSH_HOST SSH_PORT AUTHORIZED_KEYS SSH_OPTS SSH_IDENTITY_FILE
    upv tests/ssh-server provision &&\
    upv tests/http-echo provision &&\
    generate_ssh_key "${KEY_COMMENT}" "${SSH_IDENTITY_FILE}" &&\
    authorize_ssh_key_to_docker_ssh_server "${SSH_IDENTITY_FILE}" "ssh-server"
    info "Sleeping 2 seconds to let servers start"
    docker logs ssh-server && docker logs http-echo
}

ssh_socks_proxy_test() {
    upv_dotenv_get . SOCKS_PORT
    dumpenv SOCKS_PORT
    HOST_IP=`curl http://localhost:3000/ 2>/dev/null | tee /dev/stderr | jq -r .ip`
    echo
    PROXY_IP=`curl --socks5-hostname "localhost:${SOCKS_PORT}" http://localhost:3000/ 2>/dev/null | tee /dev/stderr | jq -r .ip`
    echo
    if [ "${PROXY_IP}" == "" ] || [ "${HOST_IP}" == "" ]; then
        echo " > Failed to get proxy or host ips"
        return 2
    elif [ "${PROXY_IP}" == "${HOST_IP}" ]; then
        echo " > Success"
        # TODO: test on servers with different ips - to ensure we pass through the proxy
        return 0
    fi
}
