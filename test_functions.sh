#!/usr/bin/env bash

source functions.sh

authorize_ssh_key_to_docker_ssh_server() {
    local KEY_FILE="${1}"
    local DOCKER_SSH_SERVER_NAME="${2}"
    echo "Authorizing ssh key ${KEY_FILE} to ssh into docker ssh-server container ${DOCKER_SSH_SERVER_NAME}"
    cat "${KEY_FILE}.pub" | docker exec -i "${DOCKER_SSH_SERVER_NAME}" /bin/bash -c "cat >> /root/.ssh/authorized_keys"
}

upv_submodule_provision() {
    local SUBMODULE_PATH="${1}"
    pushd "${SUBMODULE_PATH}" > /dev/null
        ./provision.sh
    popd > /dev/null
}

provision_test_environment() {
    info "Provisioning test environment"
    SSH_IDENTITY_FILE="`pwd`/test-host.key"
    echo_trim "
                KEY_COMMENT=test host key
                SSH_HOST=root@localhost
                SSH_PORT=2222
                AUTHORIZED_KEYS=/root/.ssh/authorized_keys
                PROVISION_SSH_OPTS=-o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no -i${SSH_IDENTITY_FILE}
    " > .env
    source_dotenv
    upv_submodule_provision "./docker/ssh-server" &&\
    upv_submodule_provision "./docker/http-echo" &&\
    docker_build_run "ssh-server" "./docker/ssh-server" "-d --network host" &&\
    docker_build_run "http-echo" "./docker/http-echo" "-d --network host" &&\
    generate_ssh_key "${KEY_COMMENT}" "${SSH_IDENTITY_FILE}" &&\
    authorize_ssh_key_to_docker_ssh_server "${SSH_IDENTITY_FILE}" "ssh-server" &&\
    ./provision.sh &&\
    docker_build_run "ssh-socks-proxy" "./" "-d --network host --env-file .env"
}

ssh_socks_proxy_test() {
    source_dotenv
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
