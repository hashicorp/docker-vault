FROM hashicorp/app-base-consul
MAINTAINER James Phillips <james@hashicorp.com> (@slackpad)

# Create a consul user and group first so the IDs get set the same way, even as
# the rest of this may change over time.
RUN addgroup consul && \
    adduser -S -G consul consul

# Pull down the Consul binary. BusyBox has a non-SSL capable wget so we use the host
# to fetch the file and verify inside the container.
ENV CONSUL_SHA256 b0532c61fec4a4f6d130c893fd8954ec007a6ad93effbe283a39224ed237e250
ADD https://releases.hashicorp.com/consul/0.6.3/consul_0.6.3_linux_amd64.zip /consul.zip

# Pull down and verify the Consul binary.
RUN set -x && \
    echo "${CONSUL_SHA256}  consul.zip" | sha256sum -c - && \
    unzip -d /bin consul.zip && \
    rm consul.zip

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
# usually desirable for servers so we don't include it there.
ADD client.json /consul/config/client

# Set up dnsmasq. This config location allows for easily injecting more server
# configs into a derived container.
RUN mkdir -p /dnsmasq/config

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

# DNS via dnsmasq (this is optional behavior)
EXPOSE 53 53/udp

# Consul doesn't need root privileges so we run it as the consul user from the
# entry point script. The entry point script also uses dumb-init as the top-level
# process to reap any zombie processes created by Consul sub-processes.
ADD entrypoint.sh /
ENTRYPOINT ["/entrypoint.sh"]

# By default you'll get a single-node development server that stores everything
# in RAM, exposes a web UI, and bootstraps itself. Don't use this configuration
# for production.
CMD ["dev"]