#!/usr/bin/env bash

set -xe

SCRIPT_DIR="$(cd "$(dirname -- "${BASH_SOURCE[0]}")" >/dev/null && pwd)"
source "$SCRIPT_DIR/config.sh"

# Usage: archive_log_dir <name> <log_dir> [extra_file...]
#
# Extra files are typically the console stdout/stderr captures of the daemon;
# they are only added when they exist, so a missing file never fails the tar.
function archive_log_dir {
    local archive_name="$1";shift
    local log_dir="$1";shift

    local tar=$(command -v tar)

    local epoch=$(date +%s)
    local archive_file="${QDB_LOG_ARCHIVE_PATH}/qdbd-logs-${epoch}-${archive_name}.tar.gz"

    local inputs=()
    local extra
    for extra in "$@"
    do
        if [ -f "$extra" ]
        then
            inputs+=("$extra")
        fi
    done

    if [ -d "$log_dir" ]
    then
        echo "Archiving log dir: $log_dir"
        mkdir -p "${QDB_LOG_ARCHIVE_PATH}"
        ${tar} -czvf ${archive_file} ${log_dir} ${inputs[@]+"${inputs[@]}"}
    fi
}

function archive {
    archive_log_dir insecure ${LOG_DIR_INSECURE} ${CONSOLE_LOG_INSECURE} ${CONSOLE_ERR_LOG_INSECURE}
    archive_log_dir secure   ${LOG_DIR_SECURE}   ${CONSOLE_LOG_SECURE}   ${CONSOLE_ERR_LOG_SECURE}
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
