# Build image section
FROM golang:1.9-alpine3.7 AS builder
MAINTAINER Jeff Mitchell <jeff@hashicorp.com> (@jefferai)

# This is the release of Vault to pull in.
ENV VAULT_VERSION=master

# Set up certificates, our base tools, and Vault.
RUN apk add --no-cache ca-certificates git make bash && \
    mkdir -pv /go/src/github.com/hashicorp && \
    cd /go/src/github.com/hashicorp && \
    git clone https://github.com/hashicorp/vault.git && \
    cd vault && \
    make bootstrap && \
    make dev

# Main image section
FROM alpine:3.7

# Create a vault user and group first so the IDs get set the same way,
# even as the rest of this may change over time.
RUN addgroup vault && \
    adduser -S -G vault vault

# /vault/logs is made available to use as a location to store audit logs, if
# desired; /vault/file is made available to use as a location with the file
# storage backend, if desired; the server will be started with /vault/config as
# the configuration directory so you can add additional config files in that
# location.
RUN apk add --no-cache ca-certificates libcap su-exec dumb-init && \
    mkdir -p /vault/logs && \
    mkdir -p /vault/file && \
    mkdir -p /vault/config && \
    chown -R vault:vault /vault

COPY --from=builder /go/bin/vault /usr/bin/

# Expose the logs directory as a volume since there's potentially long-running
# state in there
VOLUME /vault/logs

# Expose the file directory as a volume since there's potentially long-running
# state in there
VOLUME /vault/file

# 8200/tcp is the primary interface that applications use to interact with
# Vault.
EXPOSE 8200

# The entry point script uses dumb-init as the top-level process to reap any
# zombie processes created by Vault sub-processes.
#
# For production derivatives of this container, you shoud add the IPC_LOCK
# capability so that Vault can mlock memory.
COPY docker-entrypoint.sh /usr/local/bin/docker-entrypoint.sh
ENTRYPOINT ["docker-entrypoint.sh"]

# By default you'll get a single-node development server that stores everything
# in RAM and bootstraps itself. Don't use this configuration for production.
CMD ["server", "-dev"]
