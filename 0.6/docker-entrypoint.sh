#!/bin/dumb-init /bin/sh
set -e

# Note above that we run dumb-init as PID 1 in order to reap zombie processes
# as well as forward signals to all processes in its session. Normally, sh
# wouldn't do either of these functions so we'd leak zombies as well as do
# unclean termination of all our sub-processes.

# You can set CONSUL_BIND_INTERFACE to the name of the interface you'd like to
# bind to and this will look up the IP and pass the proper -bind= option along
# to Consul.
CONSUL_BIND=
if [ -n "$CONSUL_BIND_INTERFACE" ]; then
  CONSUL_BIND_ADDRESS=$(ip -o -4 addr list $CONSUL_BIND_INTERFACE | awk '{print $4}' | cut -d/ -f1)
  if [ -z "$CONSUL_BIND_ADDRESS" ]; then
    echo "Could not find IP for interface '$CONSUL_BIND_INTERFACE', exiting"
    exit 1
  fi

  CONSUL_BIND="-bind=$CONSUL_BIND_ADDRESS"
  echo "==> Found address '$CONSUL_BIND_ADDRESS' for interface '$CONSUL_BIND_INTERFACE', setting bind option..."
fi

# You can set CONSUL_CLIENT_INTERFACE to the name of the interface you'd like to
# bind client intefaces (HTTP, DNS, and RPC) to and this will look up the IP and
# pass the proper -client= option along to Consul.
CONSUL_CLIENT=
if [ -n "$CONSUL_CLIENT_INTERFACE" ]; then
  CONSUL_CLIENT_ADDRESS=$(ip -o -4 addr list $CONSUL_CLIENT_INTERFACE | awk '{print $4}' | cut -d/ -f1)
  if [ -z "$CONSUL_CLIENT_ADDRESS" ]; then
    echo "Could not find IP for interface '$CONSUL_CLIENT_INTERFACE', exiting"
    exit 1
  fi

  CONSUL_CLIENT="-client=$CONSUL_CLIENT_ADDRESS"
  echo "==> Found address '$CONSUL_CLIENT_ADDRESS' for interface '$CONSUL_CLIENT_INTERFACE', setting client option..."
fi

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

# The first argument is used to decide which mode we are running in. All the
# remaining arguments are passed along to Consul (or the executable if one of
# the Consul modes isn't selected).
if [ "$1" = 'dev' ]; then
    shift
    gosu consul \
        consul agent \
         -dev \
         -config-dir="$CONSUL_CONFIG_DIR/local" \
         $CONSUL_BIND \
         $CONSUL_CLIENT \
         "$@"
elif [ "$1" = 'client' ]; then
    shift
    gosu consul \
        consul agent \
         -data-dir="$CONSUL_DATA_DIR" \
         -config-dir="$CONSUL_CONFIG_DIR/client" \
         -config-dir="$CONSUL_CONFIG_DIR/local" \
         $CONSUL_BIND \
         $CONSUL_CLIENT \
         "$@"
elif [ "$1" = 'server' ]; then
    shift
    gosu consul \
        consul agent \
         -server \
         -data-dir="$CONSUL_DATA_DIR" \
         -config-dir="$CONSUL_CONFIG_DIR/server" \
         -config-dir="$CONSUL_CONFIG_DIR/local" \
         $CONSUL_BIND \
         $CONSUL_CLIENT \
         "$@"
else
    exec "$@"
fi
