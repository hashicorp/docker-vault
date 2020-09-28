#!/usr/bin/dumb-init /bin/sh
set -e

# Note above that we run dumb-init as PID 1 in order to reap zombie processes
# as well as forward signals to all processes in its session. Normally, sh
# wouldn't do either of these functions so we'd leak zombies as well as do
# unclean termination of all our sub-processes.

# Prevent core dumps
ulimit -c 0

echo 'Setting up environment variable'
# Get the secrets from AWS secret manager only for non-development environments
if [ "$VAULT_ENV" != "development" ]; then
  ####################### FETCH THE SECRETS FROM AWS SECRET MANAGER AND EXPORT AS ENV VARIABLE ###########################
  [ -z "$CLOUD_REGION" ] && export CLOUD_REGION=$(wget http://169.254.169.254/latest/meta-data/placement/availability-zone/ -q -O - | sed -E "s/([a-z0-9-]+)[a-z]+/\1/")
  [ -z "$AWS_SM_REGION" ] && export AWS_SM_REGION=${CLOUD_REGION}

  if [ -z "${AWSSM_NAME}" ]; then
    echo "Critical error, AWSSM_NAME not set! exiting"
    exit 1
  fi

  secrets=$(aws secretsmanager get-secret-value --secret-id ${AWSSM_NAME} --region ${AWS_SM_REGION} | jq .SecretString -r )
  keys=$(echo $secrets | jq '. | keys[] ')
 
  # Loop through the keys and export them
  for key in $keys
  do
    key_new=$(echo $key | sed 's/"//g' )
    export $key_new=$(echo $secrets | jq ".[$key]" | sed 's/"//g')
  done

  ######## Get RDS cert from AWS Secret Manager and store in file
  STAGE=$(echo $AWSSM_NAME | cut -d'/' -f1)
  STAGE=${STAGE:-dev}

  echo "Getting rds certs"
  mkdir -p /etc/rds/
  export RDS_CERT_PATH=/etc/rds/rds-combined-ca-bundle.pem
  rdscerts_secret_name=${STAGE}/application/rdscerts
  echo -ne $(aws secretsmanager get-secret-value --secret-id ${rdscerts_secret_name} --region ${AWS_SM_REGION} | jq -r '.SecretString' | jq '.rds_sslca') > ${RDS_CERT_PATH}.tmp
  cat ${RDS_CERT_PATH}.tmp | tr -d '"' > ${RDS_CERT_PATH}
  rm ${RDS_CERT_PATH}.tmp
  ######## Get RDS cert from AWS Secret Manager and store in file

  ########################## FETCH THE SECRETS FROM AWS SECRET MANAGER AND EXPORT AS ENV VARIABLE ###########################
fi

if [ -n "$APP_CERT_NAME" ]; then
  secrets=$(aws secretsmanager get-secret-value --secret-id ${APP_CERT_NAME} --region ${AWS_SM_REGION} | jq .SecretString -r )
  keys=$(echo $secrets | jq '. | keys[] ')
  # Loop through the keys and export them
  for key in $keys
  do
    key_new=$(echo $key | sed 's/"//g' )
    key_value=$(echo -e $secrets | jq ".[$key]" | sed 's/"//g')
    echo -e ${key_value} >> /vault/ssl/${key_new}.pem
  done
fi

# Allow setting VAULT_REDIRECT_ADDR and VAULT_CLUSTER_ADDR using an interface
# name instead of an IP address. The interface name is specified using
# VAULT_REDIRECT_INTERFACE and VAULT_CLUSTER_INTERFACE environment variables. If
# VAULT_*_ADDR is also set, the resulting URI will combine the protocol and port
# number with the IP of the named interface.
get_addr () {
    local if_name=$1
    local uri_template=$2
    ip addr show dev $if_name | awk -v uri=$uri_template '/\s*inet\s/ { \
      ip=gensub(/(.+)\/.+/, "\\1", "g", $2); \
      print gensub(/^(.+:\/\/).+(:.+)$/, "\\1" ip "\\2", "g", uri); \
      exit}'
}

if [ -n "$VAULT_REDIRECT_INTERFACE" ]; then
    export VAULT_REDIRECT_ADDR=$(get_addr $VAULT_REDIRECT_INTERFACE ${VAULT_REDIRECT_ADDR:-"https://0.0.0.0:8200"})
    echo "Using $VAULT_REDIRECT_INTERFACE for VAULT_REDIRECT_ADDR: $VAULT_REDIRECT_ADDR"
fi
if [ -n "$VAULT_CLUSTER_INTERFACE" ]; then
    export VAULT_CLUSTER_ADDR=$(get_addr $VAULT_CLUSTER_INTERFACE ${VAULT_CLUSTER_ADDR:-"https://0.0.0.0:8201"})
    echo "Using $VAULT_CLUSTER_INTERFACE for VAULT_CLUSTER_ADDR: $VAULT_CLUSTER_ADDR"
fi

export STATSD_ADDRESS=$(get_addr $VAULT_REDIRECT_INTERFACE ${STATSD_ADDRESS:-"0.0.0.0:8125"})
echo "Using $VAULT_REDIRECT_INTERFACE for STATSD_ADDRESS: $STATSD_ADDRESS"

# VAULT_CONFIG_DIR isn't exposed as a volume but you can compose additional
# config files in there if you use this image as a base, or use
# VAULT_LOCAL_CONFIG below.
VAULT_CONFIG_DIR=/vault/config

VAULT_LOCAL_CONFIG=$(cat <<EOF

listener "tcp" {
  address         = "0.0.0.0:8200"
  cluster_address = "0.0.0.0:8201"
  tls_cert_file   = "/vault/ssl/app_ssl_certificate.pem"
  tls_key_file    = "/vault/ssl/app_ssl_certificate_key.pem"
}

storage "mysql" {
    address = "${DATABASE_HOSTNAME}"
    username = "${DATABASE_USERNAME}"
    password = "${DATABASE_PASSWORD}"
    database = "${DATABASE_NAME}"
    ha_enabled = "${VAULT_HA_ENABLED}"
    lock_table = "${VAULT_HA_LOCK_TABLE}"
    tls_ca_file = "${RDS_CERT_PATH}"
}

telemetry {
    statsd_address = "${STATSD_ADDRESS}"
}

cluster_addr  = "${VAULT_CLUSTER_ADDR}"
api_addr      = "${VAULT_REDIRECT_ADDR}"
EOF
)

# You can also set the VAULT_LOCAL_CONFIG environment variable to pass some
# Vault configuration JSON without having to bind any volumes.
if [ -n "$VAULT_LOCAL_CONFIG" ]; then
    echo "$VAULT_LOCAL_CONFIG" > "$VAULT_CONFIG_DIR/default.hcl"
fi

# If the user is trying to run Vault directly with some arguments, then
# pass them to Vault.
if [ "${1:0:1}" = '-' ]; then
    set -- vault "$@"
fi

# Look for Vault subcommands.
if [ "$1" = 'server' ]; then
    shift
    set -- vault server \
        -config="$VAULT_CONFIG_DIR" \
        "$@"
elif [ "$1" = 'version' ]; then
    # This needs a special case because there's no help output.
    set -- vault "$@"
elif vault --help "$1" 2>&1 | grep -q "vault $1"; then
    # We can't use the return code to check for the existence of a subcommand, so
    # we have to use grep to look for a pattern in the help output.
    set -- vault "$@"
fi

# If we are running Vault, make sure it executes as the proper user.
if [ "$1" = 'vault' ]; then
    if [ -z "$SKIP_CHOWN" ]; then
        # If the config dir is bind mounted then chown it
        if [ "$(stat -c %u /vault/config)" != "$(id -u vault)" ]; then
            chown -R vault:vault /vault/config || echo "Could not chown /vault/config (may not have appropriate permissions)"
        fi

        # If the logs dir is bind mounted then chown it
        if [ "$(stat -c %u /vault/logs)" != "$(id -u vault)" ]; then
            chown -R vault:vault /vault/logs
        fi

        # If the file dir is bind mounted then chown it
        if [ "$(stat -c %u /vault/file)" != "$(id -u vault)" ]; then
            chown -R vault:vault /vault/file
        fi
    fi

    if [ -z "$SKIP_SETCAP" ]; then
        # Allow mlock to avoid swapping Vault memory to disk
        setcap cap_ipc_lock=+ep $(readlink -f $(which vault))

        # In the case vault has been started in a container without IPC_LOCK privileges
        if ! vault -version 1>/dev/null 2>/dev/null; then
            >&2 echo "Couldn't start vault with IPC_LOCK. Disabling IPC_LOCK, please use --privileged or --cap-add IPC_LOCK"
            setcap cap_ipc_lock=-ep $(readlink -f $(which vault))
        fi
    fi

    if [ "$(id -u)" = '0' ]; then
      set -- su-exec vault "$@"
    fi
fi

exec "$@"