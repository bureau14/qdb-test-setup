#!/bin/bash

set -eux

SCRIPT_DIR="$(cd "$(dirname -- "${BASH_SOURCE[0]}")" >/dev/null && pwd)"
source "$SCRIPT_DIR/binaries.sh"

function qdb_add_user {
    USER_COUNT=1
    local user_list=$1;shift
    local user_private_key=$1;shift
    local username=$1;shift
    ${QDB_USER_ADD} -p ${user_list} -s ${user_private_key} -u ${username} --uid=${USER_COUNT} --superuser=1
    USER_COUNT=$((${USER_COUNT} + 1))
}

function qdb_gen_cluster_keys {
    local public_key=$1;shift
    local private_key=$1;shift
    ${QDB_CLUSTER_KEYGEN} -p ${public_key} -s ${private_key}
}

function qdb_start {
    local args=$1; shift
    local output=$1; shift
    local err_output=$1; shift

    echo "Starting ${QDBD} with args: ${args}"
    echo "Redirecting output to ${output}"
    echo "Redirecting error output to ${err_output}"

    $QDBD ${args} 1>${output} 2>${err_output} &
}

function count_instances {
    local instances_count=$(($(ps aux | grep qdbd | grep -v "grep" | wc -l)))
    echo ${instances_count}
}

function check_existing_instances {
    local instances_count=$(count_instances)
    echo "${instances_count} are running."
    if ! ${instances_count} ; then
        local instances=$(ps aux | grep qdbd | grep -v "grep")
        echo "${instances}"
    fi
}

function print_instance_log {
    local log_directory=$1;shift
    local output=$1;shift
    local err_output=$1;shift
    echo "${log_directory}: "
    cat ${log_directory}/* || true

    echo "${output}: "
    cat ${output} || true

    echo "${err_output}: "
    cat ${err_output} || true
}