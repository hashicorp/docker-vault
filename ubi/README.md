# Vault Official UBI Image Build

The UBI version of this hosted on [HashiCorp's Docker Hub for Vault](https://hub.docker.com/r/hashicorp/vault/).

There are several pieces that are used to build this image:

* We start with an UBI base image and add CA certificates in order to reach
  the HashiCorp releases server. These are useful to leave in the image so that
  the container can access Atlas features as well.
* Finally a specific Vault build is fetched and the rest of the Vault-specific
  configuration happens according to the Dockerfile.

## Submitting UBI Images to the RedHat Container Registry

Build the images:

    make build

Set the registry key and project ID (PID) for enterprise and OSS and push the images:

    export OSS_REGISTRY_KEY=...
    export ENT_REGISTRY_KEY=...
    export OSS_VAULT_PID=...
    export ENT_VAULT_PID=...
    make push-images

Part of the image push process will ask to press 'Enter' after verifying that
the build image matches the expected version. The registry key and PID can be
found in the RedHat portal.
