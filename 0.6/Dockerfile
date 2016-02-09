FROM busybox:1.24.1-glibc
MAINTAINER James Phillips <james@hashicorp.com> (@slackpad)

# This is the release of Consul to pull in.
ENV CONSUL_VERSION=0.6.3
ENV CONSUL_SHA256SUM=b0532c61fec4a4f6d130c893fd8954ec007a6ad93effbe283a39224ed237e250

# This is the release of https://github.com/hashicorp/docker-base to pull in order
# to provide signed versions of basic utilities like dumb-init and gosu.
ENV DOCKER_BASE_VERSION=0.0.2
ENV DOCKER_BASE_SHA256SUM=b40a8ba98efac6958cac4da209c4190d7146670654a6a5db3ef7ac86bf1c6c7e

# Create a consul user and group first so the IDs get set the same way, even as
# the rest of this may change over time.
RUN addgroup consul && \
    adduser -S -G consul consul

# Copy the basetool into the image so that we can securely fetch and verify
# downloads using SSL, which isn't supported by the wget included in BusyBox. This
# will take a little space in this layer which we can't avoid, but we will delete
# this later so it's not part of the final image.
COPY docker-basetool_0.0.2/* /tmp/
RUN cd /tmp && \
    sha256sum -c docker-basetool*SHA256SUMS && \
    unzip docker-basetool*.zip && \
    rm -f docker-basetool* && \
    chmod +x basetool

# Decompress the certs into the location that Go looks in by default. This will
# allow our Go-based basetool to fetch releases, and it will allow Consul to use
# Atlas features and look for newer versions of Consul via Checkpoint.
ENV CA_CERT_DIR=/system/etc/security/cacerts
RUN mkdir -p "${CA_CERT_DIR}" && \
    cd /tmp && \
    unzip -d "${CA_CERT_DIR}" basetool-certs.zip && \
    rm basetool-certs.zip

# Pull down and verify the docker-base rootfs content.
RUN cd /tmp && \
    ./basetool get https://releases.hashicorp.com/docker-base/${DOCKER_BASE_VERSION}/docker-base_${DOCKER_BASE_VERSION}_linux_amd64.zip?checksum=sha256:${DOCKER_BASE_SHA256SUM}\&archive=false base.zip && \
    unzip -d / base.zip && \
    rm base.zip

# Pull down and verify Consul, and remove the basetool since we are done downloading.
RUN cd /tmp && \
    ./basetool get https://releases.hashicorp.com/consul/${CONSUL_VERSION}/consul_${CONSUL_VERSION}_linux_amd64.zip?checksum=sha256:${CONSUL_SHA256SUM}\&archive=false consul.zip && \
    unzip -d /bin consul.zip && \
    rm consul.zip && \
    rm basetool*

# The /consul/data dir is used by Consul to store state. The agent will be started
# with /consul/config/local as the configuration directory so you can add additional
# config files in that location. There are client and server-specific locations so
# we can supply some default configs via this base image as well.
RUN mkdir -p /consul/data && \
    mkdir -p /consul/config/local && \
    mkdir -p /consul/config/client && \
    mkdir -p /consul/config/server && \
    chown -R consul:consul /consul

# Client mode has some default configuration that's good for running in containers,
# namely agents will leave the cluster if you stop the container. This isn't
# usually desirable for servers so we set the opposite for servers and also skip
# leaving when servers are interrupted.
COPY client.json /consul/config/client
COPY server.json /consul/config/server

# Expose the consul data directory as a volume since there's mutable state in there.
VOLUME /consul/data

# Server RPC
EXPOSE 8300

# Serf LAN and WAN (WAN is used only by Consul servers)
EXPOSE 8301 8301/udp 8302 8302/udp

# CLI and HTTP
EXPOSE 8400 8500

# DNS (note Consul supports UDP and TCP DNS queries)
EXPOSE 8600 8600/udp

# Consul doesn't need root privileges so we run it as the consul user from the
# entry point script. The entry point script also uses dumb-init as the top-level
# process to reap any zombie processes created by Consul sub-processes.
COPY entrypoint.sh /
ENTRYPOINT ["/entrypoint.sh"]

# By default you'll get a single-node development server that stores everything
# in RAM, exposes a web UI, and bootstraps itself. Don't use this configuration
# for production.
CMD ["dev"]