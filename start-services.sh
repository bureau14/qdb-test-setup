#!/usr/bin/env bash

set -ex

echo "QDB_ENABLE_INSECURE_CLUSTER=${QDB_ENABLE_INSECURE_CLUSTER:=1}"
echo "QDB_ENABLE_SECURE_CLUSTER=${QDB_ENABLE_SECURE_CLUSTER:=1}"

set -u

SCRIPT_DIR="$(cd "$(dirname -- "${BASH_SOURCE[0]}")" >/dev/null && pwd)"
source "$SCRIPT_DIR/config.sh" $@ # important: pass $@ as config.sh also parses our runtime args
source "$SCRIPT_DIR/utils.sh"
source "$SCRIPT_DIR/cleanup.sh"

kill_instances
full_cleanup
check_binaries

if [ "${QDB_ENABLE_SECURE_CLUSTER}" != "0" ]; then
    qdb_add_user ${USER_LIST} ${USER_PRIVATE_KEY} "test-user"
    qdb_gen_cluster_keys ${CLUSTER_PUBLIC_KEY} ${CLUSTER_PRIVATE_KEY}
fi

INSECURE_IPS=()
SECURE_IPS=()

# This whole iteration is mostly unnecessary in case there's just a single-node
# cluster (the common case), but sometimes we want to launch a cluster.
#
# In this case, we want to assign specific node ids to each node in the cluster.
# Each of them also is listening on a unique port.
#
# The clusters will end up looking like this:
#
# - port 2836, cluster insecure, node 1
# - port 2838, cluster secure, node 1
# - port 2840, cluster insecure, node 2
# - port 2842, cluster secure, node 2
# .. etc
#
# We are all providing the 'base' configuration qdbd.conf (if provided), and override
# the address etc using the `-a` `--id` flags.
COUNT=0
for NODE_ID in "${NODE_IDS[@]}"; do
    # Magic number 4, as we need 4 ports per secure/insecure "pair"
    PORT_INSECURE=$((2836 + ($COUNT * 4)))
    PORT_SECURE=$((2838 + ($COUNT * 4)))
    PORT_INSECURE_PUBLISHER=$((3836 + ($COUNT * 4)))
    PORT_SECURE_PUBLISHER=$((3838 + ($COUNT * 4)))

    THIS_DATA_DIR_INSECURE="${DATA_DIR_INSECURE}/${NODE_ID}"
    THIS_LOG_DIR_INSECURE="${LOG_DIR_INSECURE}/${NODE_ID}"
    THIS_DATA_DIR_SECURE="${DATA_DIR_SECURE}/${NODE_ID}"
    THIS_LOG_DIR_SECURE="${LOG_DIR_SECURE}/${NODE_ID}"

    # Ensure directories exist
    mkdir -p ${THIS_DATA_DIR_INSECURE} || true
    mkdir -p ${THIS_LOG_DIR_INSECURE} || true
    mkdir -p ${THIS_DATA_DIR_SECURE} || true
    mkdir -p ${THIS_LOG_DIR_SECURE} || true

    THIS_URI_INSECURE="127.0.0.1:${PORT_INSECURE}"
    THIS_URI_SECURE="127.0.0.1:${PORT_SECURE}"
    THIS_URI_INSECURE_PUBLISHER="127.0.0.1:${PORT_INSECURE_PUBLISHER}"
    THIS_URI_SECURE_PUBLISHER="127.0.0.1:${PORT_SECURE_PUBLISHER}"

    INSECURE_IPS+=(${THIS_URI_INSECURE})
    SECURE_IPS+=(${THIS_URI_SECURE})

    ARGS_COMMON="--id ${NODE_ID} --enable-performance-profiling --total-sessions 512 --with-firehose \$qdb.firehose --publish-firehose=true "
    if [[ -f "${LICENSE_FILE}" ]]
    then
        ARGS_COMMON="${ARGS_COMMON} --license-file=${LICENSE_FILE}"
    fi
    
    if [ "${QDB_ENABLE_INSECURE_CLUSTER}" != "0" ]; then
        echo "Cluster insecure:"
        ARGS_INSECURE="${ARGS_COMMON} -a ${THIS_URI_INSECURE} -r ${THIS_DATA_DIR_INSECURE} -l ${THIS_LOG_DIR_INSECURE} --firehose-endpoint ${THIS_URI_INSECURE_PUBLISHER}"
        if [[ -f ${CONFIG_INSECURE} ]]; then
            ARGS_INSECURE="${ARGS_INSECURE} -c ${CONFIG_INSECURE}"
        fi

        if [[ "$COUNT" != "0" ]]; then
            # Not the first node, which means we need to bootstrap using the previous node
            BOOTSTRAP_PORT_INSECURE=$((2836 + (($COUNT - 1) * 4)))
            BOOTSTRAP_URI_INSECURE="127.0.0.1:${BOOTSTRAP_PORT_INSECURE}"
            ARGS_INSECURE="${ARGS_INSECURE} --peer ${BOOTSTRAP_URI_INSECURE}"
        fi

        qdb_start "${ARGS_INSECURE}" ${CONSOLE_LOG_INSECURE} ${CONSOLE_ERR_LOG_INSECURE}
    fi

    if [ "${QDB_ENABLE_SECURE_CLUSTER}" != "0" ]; then
        echo "Cluster secure:"
        ARGS_SECURE="${ARGS_COMMON} -a ${THIS_URI_SECURE} -r ${THIS_DATA_DIR_SECURE} -l ${THIS_LOG_DIR_SECURE} --firehose-endpoint ${THIS_URI_SECURE_PUBLISHER} --security=true --cluster-private-file=${CLUSTER_PRIVATE_KEY} --user-list=${USER_LIST}"
        if [[ -f ${CONFIG_SECURE} ]]; then
            ARGS_SECURE="${ARGS_SECURE} -c ${CONFIG_SECURE}"
        fi
        qdb_start "${ARGS_SECURE}" ${CONSOLE_LOG_SECURE} ${CONSOLE_ERR_LOG_SECURE}
    fi

    COUNT=$((COUNT + 1))
done

sleep_time=1

BUILD_TYPE=${CMAKE_BUILD_TYPE:-"Release"}
if [[ ${CMAKE_BUILD_TYPE} == "Debug" ]]
then
    sleep_time=3
fi
timeout=60
end_time=$(($(date +%s) + $timeout))
SUCCESS=1
while [ $(date +%s) -le $end_time ]; do
    if [ "${QDB_ENABLE_INSECURE_CLUSTER}" != "0" ]; then
        insecure_check=$(check_address $URI_INSECURE)
    else
        insecure_check="OK skipped"
    fi

    if [ "${QDB_ENABLE_SECURE_CLUSTER}" != "0" ]; then
        secure_check=$(check_address $URI_SECURE)
    else
        secure_check="OK skipped"
    fi

    if [[ "$insecure_check" != "" && "$secure_check" != "" ]]; then
        echo "qdbd secure and insecure were started properly."
        SUCCESS=0
        break
    fi

    sleep $sleep_time
done

if [[ "${SUCCESS}" != "0" ]]; then
    echo "Could not start all instances, aborting..."

    if [ "${QDB_ENABLE_INSECURE_CLUSTER}" != "0" ]; then
        echo "Insecure out:"
        cat ${CONSOLE_LOG_INSECURE}
        echo "Insecure err:"
        cat ${CONSOLE_ERR_LOG_INSECURE}
    fi

    if [ "${QDB_ENABLE_SECURE_CLUSTER}" != "0" ]; then
        echo "Secure out:"
        cat ${CONSOLE_LOG_SECURE}
        echo "Secure err:"
        cat ${CONSOLE_ERR_LOG_SECURE}
    fi

    exit 1
fi

function join_with_char() {
    local IFS="$1"; shift
    echo "$*"
}

sleep $sleep_time

function stabilize() {
    local PARAMS="$1"; shift

    local NODE_IPS=($*)

    NODE_URI=$(
        echo -n 'qdb://'
        join_with_char ',' "${NODE_IPS[@]}"
    )
    echo "Stabilizing cluster ${NODE_URI}..."

    SUCCESS=1
    # Clustered setup, wait for stabilization
    timeout=300 # stabilization can take a long time!
    end_time=$(($(date +%s) + $timeout))
    sleep_time=1
    while [ $(date +%s) -le $end_time ]; do
        check=$(
            cluster_wait_for_stabilization \
            --cluster ${NODE_URI} \
            ${PARAMS} \
        )

        if [[ "${check}" == "0" ]]; then
            echo "cluster ${NODE_URI} is stable!"
            SUCCESS=0
            break
        fi

        echo "Cluster ${NODE_URI} is not stable, sleeping for ${sleep_time}s before retry.."
        sleep $sleep_time
    done

    if [[ "${SUCCESS}" != "0" ]]; then
        echo "Cluster ${NODE_URI} did not become stable, abort!"
        exit 1
    fi
}

if [[ ${#NODE_IDS[@]} -gt 1 ]]; then
    # Stabilize each node separately and all nodes together.
    if [ "${QDB_ENABLE_INSECURE_CLUSTER}" != "0" ]; then
        for NODE_IP in "${INSECURE_IPS[@]}"; do
            stabilize "" "${NODE_IP}"
        done
        stabilize "" "${INSECURE_IPS[@]}"
    fi

    if [ "${QDB_ENABLE_SECURE_CLUSTER}" != "0" ]; then
        PARAMS="\
            --cluster-public-key ${CLUSTER_PUBLIC_KEY} \
            --user-security-file ${USER_PRIVATE_KEY}
        "
        for NODE_IP in "${SECURE_IPS[@]}"; do
            stabilize "${PARAMS}" "${NODE_IP}"
        done
        stabilize "${PARAMS}" "${SECURE_IPS[@]}"
    fi
fi
