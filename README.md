# qdb-test-setup

The goal of this project is to provide reusable test setup to run and stop qdbd instances.
It can run on any platform as long as it is run in bash.

Its functions are simple:
1. Find quasardb binaries
1. Create public and private keys for the server
1. Add a user
1. Run qdbd in insecure mode
1. Run qdbd in secure mode
1. Stop qdbd instances reliably
1. Log everything and provide static paths for the artifacts

The expected path for the binaries is: `./qdb/bin`

## Run
`./start-services.sh`

## Stop
`./stop-services.sh`

## Cleanup
In the case you would like to fully cleanup after use (stop does not remove everything), you can use this command:

`bash -c "source ./cleanup.sh && full_cleanup"`

## Use existing credentials

Set `QDB_GENERATE_SECURITY=0` to skip credential generation and credential
deletion during startup, stop and cleanup. Custom file paths alone do not disable
these operations. For example, to run cluster with existing files:

```bash
export QDB_GENERATE_SECURITY=0
export USER_LIST=/path/to/users.cfg
export USER_PRIVATE_KEY=/path/to/user_private.key
export CLUSTER_PUBLIC_KEY=/path/to/cluster_public.key
export CLUSTER_PRIVATE_KEY=/path/to/cluster_private.key
./start-services.sh
```

Provide the files required by your setup. Keep the same exported settings when running `./stop-services.sh`
so they also preserve the supplied credentials.

Keep credentials, configuration and license files outside the data/log/archive
directories and console-output paths: those outputs can be archived, overwritten
or removed even when `QDB_GENERATE_SECURITY=0`.

## Listen on a specific IP

By default, servers listen on `127.0.0.1`. Set `QDB_IP` to an address assigned to
the server to use it for listeners, publisher endpoints, peers and readiness
checks. Replace the example address with the server's actual IP:

```bash
export QDB_IP=192.168.1.10
./start-services.sh
```
