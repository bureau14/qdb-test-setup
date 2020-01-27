#!/bin/bash

set -xe

if [[ -z ${QDB_DIR+set} ]]; then
    QDB_DIR="qdb/bin"
    echo "Setting QDB_DIR to ${QDB_DIR}"
fi

if [[ ! -d ${QDB_DIR} ]]; then
    echo "Please provide a valid binary directory, got: ${QDB_DIR}"
    exit 1
fi

QDBD="${QDB_DIR}/qdbd"
QDBSH="${QDB_DIR}/qdbsh"
QDB_USER_ADD="${QDB_DIR}/qdb_user_add"
QDB_CLUSTER_KEYGEN="${QDB_DIR}/qdb_cluster_keygen"

set +u

if [[ ${CMAKE_BUILD_TYPE} == "Debug" ]]; then
    QDBD="${QDBD}d"
    QDB_USER_ADD="${QDB_USER_ADD}d"
    QDB_CLUSTER_KEYGEN="${QDB_CLUSTER_KEYGEN}d"
fi

set -u

case "$(uname)" in
    MINGW*)
        QDBD=${QDBD}.exe
        QDB_USER_ADD=${QDB_USER_ADD}.exe
        QDB_CLUSTER_KEYGEN=${QDB_CLUSTER_KEYGEN}.exe
    ;;
    *)
    ;;
esac

FOUND=0
if [[ ! -f ${QDBD} ]]; then
    echo "Binary ${QDBD} not found."
    FOUND=1
fi
if [[ ! -f ${QDB_USER_ADD} ]]; then
    echo "Binary ${QDB_USER_ADD} not found."
    FOUND=1
fi
if [[ ! -f ${QDB_CLUSTER_KEYGEN} ]]; then
    echo "Binary ${QDB_CLUSTER_KEYGEN} not found."
    FOUND=1
fi

if [[ ${FOUND} != 0 ]] ; then
    echo "Binaries not found. Exiting..."
    exit 1
fi

QDBD_FILENAME=${QDBD##*/}
