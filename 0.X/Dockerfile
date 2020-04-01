# This is the release of Alpine to use
ARG ALPINE_VERSION=3.10

FROM alpine:$ALPINE_VERSION AS builder

# This is the release of Vault to pull in
ARG VAULT_VERSION=1.4.0-rc1

# Set up certificates, tools and Vault
RUN set -eux; \
    apk add --no-cache ca-certificates gnupg openssl && \
    apkArch="$(apk --print-arch)"; \
    case "$apkArch" in \
        armhf) ARCH='arm' ;; \
        aarch64) ARCH='arm64' ;; \
        x86_64) ARCH='amd64' ;; \
        x86) ARCH='386' ;; \
        *) echo >&2 "error: unsupported architecture: $apkArch"; exit 1 ;; \
    esac && \
    VAULT_GPGKEY=91A6E7F85D05C65630BEF18951852D87348FFC4C; \
    found=''; \
    for server in \
        hkp://p80.pool.sks-keyservers.net:80 \
        hkp://keyserver.ubuntu.com:80 \
        hkp://pgp.mit.edu:80 \
    ; do \
        echo "Fetching GPG key $VAULT_GPGKEY from $server"; \
        gpg --batch --keyserver "$server" --recv-keys "$VAULT_GPGKEY" && found=yes && break; \
    done; \
    test -z "$found" && echo >&2 "error: failed to fetch GPG key $VAULT_GPGKEY" && exit 1; \
    mkdir -p /tmp/build && \
    cd /tmp/build && \
    wget https://releases.hashicorp.com/vault/${VAULT_VERSION}/vault_${VAULT_VERSION}_linux_${ARCH}.zip && \
    wget https://releases.hashicorp.com/vault/${VAULT_VERSION}/vault_${VAULT_VERSION}_SHA256SUMS && \
    wget https://releases.hashicorp.com/vault/${VAULT_VERSION}/vault_${VAULT_VERSION}_SHA256SUMS.sig && \
    gpg --batch --verify vault_${VAULT_VERSION}_SHA256SUMS.sig vault_${VAULT_VERSION}_SHA256SUMS && \
    grep vault_${VAULT_VERSION}_linux_${ARCH}.zip vault_${VAULT_VERSION}_SHA256SUMS | sha256sum -c && \
    unzip -d /usr/local/bin vault_${VAULT_VERSION}_linux_${ARCH}.zip

FROM alpine:$ALPINE_VERSION

# Set Image Metadata
LABEL io.k8s.description="Vault is a tool for securely accessing secrets" \
      io.openshift.min-cpu="2" \
      io.openshift.min-memory="4Gi" \
      io.openshift.tags="hashicorp,secrets,vault"

# Set up certificates and tools
RUN apk add --no-cache ca-certificates dumb-init

# /vault/logs is made available to use as a location to store audit logs, if
# desired; /vault/file is made available to use as a location with the file
# storage backend, if desired; the server will be started with /vault/config as
# the configuration directory so you can add additional config files in that
# location.
RUN mkdir -p /home/vault /vault/config /vault/file /vault/logs \
 && chgrp -R 0 /home/vault /vault \
 && chmod -R g+rwX /home/vault /vault

# Expose the file- and logs directory as a volumes since there's potentially
# long-running state in there.
VOLUME /vault/file /vault/logs

# 8200/tcp is the primary interface that applications use to interact with
# Vault
EXPOSE 8200/tcp

# Copy Vault from builder
COPY --from=builder /usr/local/bin/vault /usr/local/bin/vault

# The entry point script uses dumb-init as the top-level process to reap any
# zombie processes created by Vault sub-processes.
#
# For production derivatives of this container, you shoud add the IPC_LOCK
# capability so that Vault can mlock memory.
COPY docker-entrypoint.sh /usr/local/bin/docker-entrypoint.sh
ENTRYPOINT ["/usr/local/bin/docker-entrypoint.sh"]

# Set home directory manually
ENV HOME=/home/vault
WORKDIR $HOME

# Signal that the image doesn't need to be executed ar root
USER 1001

# By default you'll get a single-node development server that stores everything
# in RAM and bootstraps itself. Don't use this configuration for production
CMD ["server", "-dev"]
