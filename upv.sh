#!/usr/bin/env bash

help() {
    echo "Usage: ${0} [--debug] [--interactive] <UPV_MODULE_PATH> [CMD] [PARAMS]"
}

preflight_check() {
    local CHECK="${1}"
    local ERROR="${2}"
    local INSTALL="${3}"
    if ! eval "${CHECK}" >/dev/null 2>&1; then
        echo "ERROR: ${ERROR}"
        if [ "${UPV_INTERACTIVE}" == "1" ]; then
            read -p "Try to install? [Y/n] "
            if [ "${REPLY}" == "n" ]; then
                return 1
            else
                eval "${INSTALL}"
            fi
        else
            echo "Run ./upv.sh --interactive to let the script try installing dependencies for you"
            return 1
        fi
    else
        return 0
    fi
}

preflight() {
    preflight_check "which python2.7" "Python 2.7 is required" "sudo apt-get install python2.7" &&\
    preflight_check "which docker" "Docker is required" "
        curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -;
        sudo add-apt-repository \"deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable\";
        sudo apt-get update;
        sudo apt-get -y install docker-ce;
    "
}

debug() {
    [ "${UPV_DEBUG}" == "0" ] || echo "$@"
}

dumpenv() {
    printf " -- "
    for PARAM in "$@"; do
        DOLLARPARAM='$'`echo $PARAM`
        VALUE=`eval "echo $DOLLARPARAM"`
        printf "${PARAM}=\"${VALUE}\" "
    done
    echo
}

read_params() {
    if [ "${1}" == "--debug" ] || [ "${2}" == "--debug" ]; then
        UPV_DEBUG=1
    else
        UPV_DEBUG=0
    fi

    if [ "${1}" == "--interactive" ] || [ "${2}" == "--interactive" ]; then
        UPV_INTERACTIVE=1
    else
        UPV_INTERACTIVE=0
    fi

    if [ "${2}" == "--interactive" ] || [ "${2}" == "--debug" ]; then
        UPV_MODULE_PATH="${3}"
        CMD="${4}"
        PARAMS="${5}"
    elif [ "${1}" == "--interactive" ] || [ "${1}" == "--debug" ]; then
        UPV_MODULE_PATH="${2}"
        CMD="${3}"
        PARAMS="${4}"
    else
        UPV_MODULE_PATH="${1}"
        CMD="${2}"
        PARAMS="${3}"
    fi
    # export UPV_DEBUG UPV_INTERACTIVE UPV_MODULE_PATH CMD PARAMS
}

read_params "$@"

if ! preflight; then
    echo "ERROR: Failed preflight checks"
    exit 1
fi

if [ "${UPV_MODULE_PATH}" == "" ]; then
    help
    exit 1
fi

debug "Running upv.sh (pwd=`pwd`)"
debug `dumpenv UPV_MODULE_PATH CMD PARAMS UPV_DEBUG UPV_INTERACTIVE`

if [ -f "${UPV_MODULE_PATH}/upv.yaml" ]; then
    debug "found an upv.yaml file in the module path"
    UPV_DOCKER_PATH=`python -c "import yaml; print(yaml.load(open('${UPV_MODULE_PATH}/upv.yaml')).get('upv_docker_path', ''))"`
    if [ "${UPV_DOCKER_PATH}" != "" ]; then
        debug "module upv.yaml has an upv_docker_path attribute, will build and run inside it instead of the root upv container"
        UPV_DOCKER_PATH="${UPV_MODULE_PATH}/${UPV_DOCKER_PATH}"
        debug `dumpenv UPV_DOCKER_PATH`
    fi
fi
if [ "${UPV_DOCKER_PATH}" == "" ] && [ "${UPV_ROOT}" != "" ] && [ "${UPV_WORKSPACE}" != "" ] &&\
   [ -f "${UPV_ROOT}/functions.sh" ] && [ -d "${UPV_WORKSPACE}" ]
then
    debug "no custom upv image and we are already inside a container, will optimize and run the code directly in current container"
    source "${UPV_ROOT}/functions.sh"
    upv "${UPV_MODULE_PATH}" "${CMD}" "${PARAMS}"
    exit $?
else
    echo "Starting upv..."
    if [ "${UPV_DOCKER_PATH}" == "" ] && [ -f ./upv.yaml ]; then
        UPV_DOCKER_PATH=`python -c "import yaml; print(yaml.load(open('./upv.yaml')).get('upv_docker_path', ''))"`
    fi
    debug `dumpenv UPV_DOCKER_PATH`
    if [ "${UPV_DOCKER_PATH}" == "" ]; then
        echo "Failed to find suitable upv docker directory to build from"
        exit 1
    else
        debug "Building an upv image from ${UPV_DOCKER_PATH}"
        DOCKER_IMAGE=`docker build -q "${UPV_DOCKER_PATH}"`
        debug "Running image ${DOCKER_IMAGE}"
        docker run -it --rm --network host \
                   -v "`pwd`:/upv/workspace" \
                   -v "/var/run/docker.sock:/var/run/docker.sock" \
                   -v "${HOME}/.docker:/root/.docker" \
                   -e "UPV_DEBUG=${UPV_DEBUG}" \
                   -e "UPV_INTERACTIVE=${UPV_INTERACTIVE}" \
                   -e "UPV_WORKSPACE=/upv/workspace" \
                   -e "UPV_ROOT=/upv" \
                   "${DOCKER_IMAGE}" "${UPV_MODULE_PATH}" "${CMD}" "${PARAMS}"
        RES=$?
        debug "Upv exited with return code ${RES}"
        debug "Removing image"
        docker rmi --no-prune "${DOCKER_IMAGE}" >/dev/null 2>&1
        exit $RES
    fi
fi
