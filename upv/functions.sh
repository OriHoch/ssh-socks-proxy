error() {
    echo "ERROR: ${*}"
}

warning() {
    echo "WARNING: ${*}"
}

info() {
    echo "INFO: ${*}"
}

debug() {
    [ "${UPV_DEBUG}" == "0" ] || echo "DEBUG: ${*}"
}

success() {
    echo "Great Success"
    echo
    echo_trim "${1}"
}

upv() {
    local SUBMODULE_PATH="${1}"
    local CMD="${2}"
    local PARAMS="${3}"
    debug "upv"
    debug `dumpenv SUBMODULE_PATH UPV_WORKSPACE`
    pushd "${UPV_WORKSPACE}/${SUBMODULE_PATH}" >/dev/null
        upv_exec "${CMD}" "${PARAMS}"
        RES=$?
    popd >/dev/null
    return $RES
}

upv_exec() {
    local CMD="${1}"
    local PARAMS="${2}"
    debug "upv_exec (pwd=`pwd`)"
    debug `dumpenv CMD PARAMS UPV_WORKSPACE UPV_ROOT`
    if [ "${CMD}" != "" ]; then
        if [ -f "./${CMD}.sh" ]; then
            "./${CMD}.sh" $PARAMS
        elif [ -f "./${CMD}.py" ]; then
            python "./${CMD}.py" $PARAMS
        elif [ -f "${UPV_ROOT}/${CMD}.sh" ]; then
            "${UPV_ROOT}/${CMD}.sh" $PARAMS
        elif [ -f "${UPV_ROOT}/${CMD}.py" ]; then
            python "${UPV_ROOT}/${CMD}.py" $PARAMS
        else
            echo "Unkown command: ${CMD}"
            exit 1
        fi
    else
        bash
    fi
}

bash_on_error() {
    if [ "${UPV_DEBUG}" == "1" ] && [ "${UPV_INTERACTIVE}" == "1" ]; then
        dumpenv UPV_DEBUG UPV_INTERACTIVE
        echo "Starting bash on error"
        bash
    fi
}

source_dotenv() {
    [ -f .env ] || touch .env
    eval `dotenv list`
}

dotenv_set() {
    [ -f .env ] || touch .env
    debug `dotenv -qnever set -- "${1}" "${2}"`
}

upv_dotenv_set() {
    local UPV_MODULE_PATH="${1}"
    local KEY="${2}"
    local VAL="${3}"
    pushd "${UPV_WORKSPACE}/${UPV_MODULE_PATH}" >/dev/null
        dotenv_set "${KEY}" "${VAL}"
    popd >/dev/null
    eval "${KEY}=\"${VAL}\""
}

upv_dotenv_get() {
    local UPV_MODULE_PATH="${1}"
    local KEY="${2}"
    pushd "${UPV_WORKSPACE}/${UPV_MODULE_PATH}" >/dev/null
        [ -f .env ] || touch .env
        eval `dotenv get "${KEY}"`
    popd >/dev/null
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
            if [ "${UPV_INTERACTIVE}" == "0" ]; then
                error "Missing required param ${PARAM}"
                info "Run ./upv.sh --interactive to interactively input the values"
                bash_on_error
                return 1
            else
                read -p "${PARAM}=" $PARAM
            fi
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
    local NAME="${1}"
    local DOCKER_RUN_PARAMS="${2}"
    local WAIT_TO_START_SECONDS="${3}"
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

docker_wait() {
    local NAME="${1}"
    local NUM_SECONDS="${2}"
    info "Waiting ${NUM_SECONDS} for docker container ${NAME} to start"
    docker logs -f "${NAME}" &
    sleep $NUM_SECONDS
    kill %1
    wait %1
    if ! docker ps | tee /dev/stderr | grep " ${NAME} "; then
        return 1
    else
        return 0
    fi
}
