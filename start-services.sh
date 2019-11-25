#!/bin/bash

set -eux

SCRIPT_DIR="$(cd "$(dirname -- "${BASH_SOURCE[0]}")" >/dev/null && pwd)"
source "$SCRIPT_DIR/config.sh"
source "$SCRIPT_DIR/utils.sh"
source "$SCRIPT_DIR/cleanup.sh"

full_cleanup

qdb_add_user ${USER_LIST} ${USER_PRIVATE_KEY} "test-user"
qdb_gen_cluster_keys ${CLUSTER_PUBLIC_KEY} ${CLUSTER_PRIVATE_KEY}

echo "Cluster insecure:"
ARGS_INSECURE="-a ${URI_INSECURE} -r ${DATA_DIR_INSECURE} -l ${LOG_DIR_INSECURE}"
if [[ -f ${CONFIG_INSECURE} ]]; then
    ARGS_INSECURE="${ARGS_INSECURE} -c ${CONFIG_INSECURE}"
fi
qdb_start "${ARGS_INSECURE}" ${CONSOLE_LOG_INSECURE} ${CONSOLE_ERR_LOG_INSECURE}

echo "Cluster secure:"
ARGS_SECURE="-a ${URI_SECURE} -r ${DATA_DIR_SECURE} -l ${LOG_DIR_SECURE} --security=true --cluster-private-file=${CLUSTER_PRIVATE_KEY} --user-list=${USER_LIST}"
if [[ -f ${CONFIG_SECURE} ]]; then
    ARGS_SECURE="${ARGS_SECURE} -c ${CONFIG_SECURE}"
fi
qdb_start "${ARGS_SECURE}" ${CONSOLE_LOG_SECURE} ${CONSOLE_ERR_LOG_SECURE}

sleep_time=5
timeout=60
end_time=$(($(date +%s) + $timeout))
while [ $(date +%s) -le $end_time ]; do
    instances_running=$(count_instances)
    if [[ $((${instances_running})) == 2 ]] ; then
        echo "${instances_running} ${QDBD_FILENAME} instances were started properly."
        exit 0
    else
        instances_not_start=$((2 - ${instances_running}))
        echo "$instances_not_start ${QDBD_FILENAME} instances were not yet started."
    fi
    sleep $sleep_time
done

echo "Could not start all instances, aborting..."
exit 1
