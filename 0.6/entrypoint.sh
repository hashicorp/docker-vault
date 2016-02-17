#!/bin/dumb-init /bin/sh
set -e

# Note above that we run dumb-init as PID 1 in order to reap zombie processes
# as well as forward signals to all processes in its session. Normally, sh
# wouldn't do either of these functions so we'd leak zombies as well as do
# unclean termination of all our sub-processes.

# This exposes three different modes, and allows for the execution of arbitrary
# commands if one of these modes isn't chosen. Each of the modes will read from
# the config directory, allowing for easy customization by placing JSON files
# there. Note that there's a common config location, as well as one specifc to
# the server and agent modes.
CONSUL_DATA_DIR=/consul/data
CONSUL_CONFIG_DIR=/consul/config

# You can also set the CONSUL_LOCAL_CONFIG environemnt variable to pass some
# Consul configuration JSON without having to bind any volumes.
if [ -n "$CONSUL_LOCAL_CONFIG" ]; then
	echo "$CONSUL_LOCAL_CONFIG" > "$CONSUL_CONFIG_DIR/local/env.json"
fi

if [ "$1" = 'dev' ]; then
    shift
    gosu consul \
        consul agent \
         -dev \
         -config-dir="$CONSUL_CONFIG_DIR/local" \
         "$@"
elif [ "$1" = 'client' ]; then
    shift
    gosu consul \
        consul agent \
         -data-dir="$CONSUL_DATA_DIR" \
         -config-dir="$CONSUL_CONFIG_DIR/client" \
         -config-dir="$CONSUL_CONFIG_DIR/local" \
         "$@"
elif [ "$1" = 'server' ]; then
    shift
    gosu consul \
        consul agent \
         -server \
         -data-dir="$CONSUL_DATA_DIR" \
         -config-dir="$CONSUL_CONFIG_DIR/server" \
         -config-dir="$CONSUL_CONFIG_DIR/local" \
         "$@"
else
    exec "$@"
fi
