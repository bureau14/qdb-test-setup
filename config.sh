#!/usr/bin/env bash

set -xe

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)"

# Static config

# Use `: ${VAR:=default_value_if_not_set}` for configurable variables.
# `:` is a no-op.

: ${USER_LIST:="users.cfg"}
: ${USER_PRIVATE_KEY:="user_private.key"}
: ${CLUSTER_PUBLIC_KEY:="cluster_public.key"}
: ${CLUSTER_PRIVATE_KEY:="cluster_private.key"}

: ${DATA_DIR_INSECURE:="insecure/db"}
: ${LOG_DIR_INSECURE:="insecure/log"}
: ${URI_INSECURE:="127.0.0.1:2836"}
: ${CONFIG_INSECURE:="${SCRIPT_DIR}/default.qdbd.cfg"}
: ${CONSOLE_LOG_INSECURE:="qdbd_log_insecure.out.txt"}
: ${CONSOLE_ERR_LOG_INSECURE:="qdbd_log_insecure.err.txt"}

: ${DATA_DIR_SECURE:="secure/db"}
: ${LOG_DIR_SECURE:="secure/log"}
: ${URI_SECURE:="127.0.0.1:2838"}
: ${CONFIG_SECURE:="${SCRIPT_DIR}/default.qdbd.cfg"}
: ${CONSOLE_LOG_SECURE:="qdbd_log_secure.out.txt"}
: ${CONSOLE_ERR_LOG_SECURE:="qdbd_log_secure.err.txt"}
: ${QDB_LOG_ARCHIVE_PATH:="${SCRIPT_DIR}/logs"}

: ${LICENSE_FILE:="license.key"}


if [ ! -d ${QDB_LOG_ARCHIVE_PATH} ]
then
    echo "Log archive path ${QDB_LOG_ARCHIVE_PATH} does not yet exist, creating..."
    mkdir -v -p ${QDB_LOG_ARCHIVE_PATH}
fi

# Sanitize the variable 'QDB_SECURITY_MODE' into the booleans
# 'QDB_ENABLE_SECURE_CLUSTER}' and 'QDB_ENABLE_INSECURE_CLUSTER'.
: ${QDB_SECURITY_MODE:="both"}

if [[ "${QDB_SECURITY_MODE}" == "both" ]] || [[ "${QDB_SECURITY_MODE}" == "secure" ]]
then
    echo "Enabling secure cluster"
    QDB_ENABLE_SECURE_CLUSTER=1
else
    echo "Disabling secure cluster"
    QDB_ENABLE_SECURE_CLUSTER=0
fi

if [[ "${QDB_SECURITY_MODE}" == "both" ]] || [[ "${QDB_SECURITY_MODE}" == "insecure" ]]
then
    echo "Enabling insecure cluster"
    QDB_ENABLE_INSECURE_CLUSTER=1
else
    echo "Disabling insecure cluster"
    QDB_ENABLE_INSECURE_CLUSTER=0
fi

: ${QDB_ENCRYPT_TRAFFIC:=0}

if [[ "${QDB_ENCRYPT_TRAFFIC}" != "0" ]]
then
    echo "Enabling full stream encryption"
    QDB_ENCRYPT_TRAFFIC=1
fi

# Runtime configuration, parse arguments
NODE_IDS=("0-0-0-1")

# StackOverflow-driven development
# - https://stackoverflow.com/a/14203146
while [[ $# -gt 0 ]]; do
    key="$1"

    case $key in
    -i | --node-ids)
        # Node IDS are a comma-separated list
        IFS=', ' read -r -a NODE_IDS <<<"$2"
        shift # past argument
        shift # past value
        ;;
    esac
done
