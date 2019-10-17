#!/bin/bash

set -xe

USER_LIST="users.cfg"
USER_PRIVATE_KEY="user_private.key"
CLUSTER_PUBLIC_KEY="cluster_public.key"
CLUSTER_PRIVATE_KEY="cluster_private.key"

DATA_DIR_INSECURE="insecure/db"
LOG_DIR_INSECURE="insecure/log"
URI_INSECURE="127.0.0.1:2836"
CONFIG_INSECURE="qdbd_insecure.cfg"
CONSOLE_LOG_INSECURE="qdbd_log_insecure.out.txt"
CONSOLE_ERR_LOG_INSECURE="qdbd_log_insecure.err.txt"

DATA_DIR_SECURE="secure/db"
LOG_DIR_SECURE="secure/log"
URI_SECURE="127.0.0.1:2838"
CONFIG_SECURE="qdbd_secure.cfg"
CONSOLE_LOG_SECURE="qdbd_log_secure.out.txt"
CONSOLE_ERR_LOG_SECURE="qdbd_log_secure.err.txt"
