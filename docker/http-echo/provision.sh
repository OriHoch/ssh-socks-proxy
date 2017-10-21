#!/usr/bin/env bash

error() {
    echo "ERROR: ${*}"
}

warning() {
    echo "WARNING: ${*}"
}

info() {
    echo "INFO: ${*}"
}

source_dotenv() {
    info "sourcing .env file"
    [ ! -f .env ] || eval `dotenv list`
}

echo_trim() {
    echo "${*}" | (
        while read -r line; do
            if [ "${line}" != "" ]; then
                echo $line
            fi
        done
    )
}

graceful_handler() {
    local PIDS="${1}"
    local TEMPDIR="${2}"
    if [ "${PIDS}" != "" ]; then
        echo "graceful shutdown (PIDS = ${PIDS})"
        for PID in $PIDS; do kill -TERM "${PIDS}"; done
        for PID in $PIDS; do wait "${PIDS}"; done
    fi
    if [ "${TEMPDIR}" != "" ]; then
        rm -rf $TEMPDIR
    fi
    exit 0
}

read_params() {
    for PARAM in $*; do
        local VALUE=`eval 'echo $'${PARAM}`
        if [ "${VALUE}" == "" ]; then
            read -p "${PARAM}=" $PARAM
        else
            echo "${PARAM}=\"${VALUE}\""
        fi
    done
}

require_params() {
    for PARAM in "$@"; do
        local VALUE=`eval 'echo $'${PARAM}`
        if [ "${VALUE}" == "" ]; then
            echo "Missing required env var: ${PARAM}"
            return 1
        fi
    done
    return 0
}

ensure_file_not_exists() {
    for PARAM in "$@"; do
        if [ -f "${PARAM}" ]; then
            warning "deleting existing file ${PARAM}"
            rm -f "${PARAM}"
        fi
    done
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

dumpenv_secret() {
    printf " -- "
    for PARAM in "$@"; do
        DOLLARPARAM='$'`echo $PARAM`
        VALUE=`eval "echo $DOLLARPARAM"`
        if [ "${VALUE}" != "" ]; then
            VALUE="*******"
        fi
        printf "${PARAM}=\"${VALUE}\" "
    done
    echo
}

docker_build() {
    local NAME="${1}"; local DOCKER_BUILD_PATH="${2}"; local BUILD_LOG_FILE="${3}"
    info "Building docker image"
    dumpenv NAME DOCKER_BUILD_PATH BUILD_LOG_FILE
    docker build -t "${NAME}" "${DOCKER_BUILD_PATH}" > $BUILD_LOG_FILE
}

docker_run() {
    local NAME="${1}"; local DOCKER_RUN_PARAMS="${2}"
    info "Running docker container"
    dumpenv NAME DOCKER_RUN_PARAMS
    docker rm --force "${NAME}" >/dev/null
    docker run $DOCKER_RUN_PARAMS --name "${NAME}" "${NAME}"
}

docker_build_run() {
    local NAME="${1}"
    local DOCKER_BUILD_PATH="${2}"
    local DOCKER_RUN_PARAMS="${3}"
    docker_build "${NAME}" "${DOCKER_BUILD_PATH}" `mktemp`  && docker_run "${NAME}" "${DOCKER_RUN_PARAMS}"
}

docker_build_run "http-echo" "." "-d --network host"
