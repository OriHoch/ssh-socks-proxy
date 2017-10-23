#!/usr/bin/env bash

source "${UPV_ROOT}/functions.sh"

UPV_MODULE_PATH="${1}"
CMD="${2}"
PARAMS="${3}"

debug "upv entrypoint"
debug `dumpenv UPV_MODULE_PATH CMD PARAMS`
debug `dumpenv UPV_ROOT UPV_WORKSPACE`

if [ "${CMD}" != "" ]; then
    upv "${UPV_MODULE_PATH}" "${CMD}" "${PARAMS}"
else
    cd "${UPV_WORKSPACE}/${UPV_MODULE_PATH}"
    bash
fi
