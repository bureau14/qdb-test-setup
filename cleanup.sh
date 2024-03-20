#!/usr/bin/env bash

set -xe

SCRIPT_DIR="$(cd "$(dirname -- "${BASH_SOURCE[0]}")" >/dev/null && pwd)"
source "$SCRIPT_DIR/config.sh"

function archive_log_dir {
    local archive_name="$1";shift
    local log_dir="$1";shift

    local tar=$(command -v tar)

    if [ ! -d "${QDB_LOG_ARCHIVE_PATH}" ]
    then
        echo "Unable to archive: not a directory: ${QDB_LOG_ARCHIVE_PATH}"
        exit -1
    fi

    local epoch=$(date +%s)
    local archive_file="${QDB_LOG_ARCHIVE_PATH}/qdbd-logs-${epoch}-${archive_name}.tar.gz"

    if [ -d "$log_dir" ]
    then
        echo "Archiving log dir: $log_dir"
        ${tar} -czvf ${archive_file} ${log_dir}
    fi
}

function archive {
    archive_log_dir insecure ${LOG_DIR_INSECURE}
    archive_log_dir secure   ${LOG_DIR_SECURE}
}

function cleanup {
    archive

    echo "Removing ${DATA_DIR_INSECURE}..."
    rm -Rf ${DATA_DIR_INSECURE} || true

    echo "Removing ${DATA_DIR_SECURE}..."
    rm -Rf ${DATA_DIR_SECURE} || true

    rm -Rf ${USER_LIST} || true
    rm -Rf ${USER_PRIVATE_KEY} || true
    rm -Rf ${CLUSTER_PUBLIC_KEY} || true
    rm -Rf ${CLUSTER_PRIVATE_KEY} || true
}

function full_cleanup {
    cleanup
    echo "Removing ${LOG_DIR_INSECURE}..."
    rm -Rf ${LOG_DIR_INSECURE} || true
    echo "Removing ${CONSOLE_LOG_INSECURE} ..."
    rm -Rf ${CONSOLE_LOG_INSECURE} || true
    echo "Removing ${CONSOLE_ERR_LOG_INSECURE} ..."
    rm -Rf ${CONSOLE_ERR_LOG_INSECURE} || true

    echo "Removing ${LOG_DIR_SECURE}..."
    rm -Rf ${LOG_DIR_SECURE} || true
    echo "Removing ${CONSOLE_LOG_SECURE} ..."
    rm -Rf ${CONSOLE_LOG_SECURE} || true
    echo "Removing ${CONSOLE_ERR_LOG_SECURE} ..."
    rm -Rf ${CONSOLE_ERR_LOG_SECURE} || true
}
