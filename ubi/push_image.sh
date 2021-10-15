#!/usr/bin/env bash

set -e

# Check that all the required environment variables are set and not empty
: ${REGISTRY_NAME:?} # image registry from the `make build` step, currently docker.io/hashicorp
: ${PROJECT_NAME:?}  # either vault or vault-enterprise typically
: ${VAULT_VERSION:?} # built vault version (e.g. 1.8.4)
: ${TAG_SUFFIX:?}    # UBI image tag suffix, typically -ubi or -ubi-ent
: ${VAULT_PID:?}     # image UUID from the redhat portal
: ${REGISTRY_KEY:?}  # image registry key from the redhat portal

# This is just a safety catch, it checks that the image is built locally, and
# prints out the Vault version from inside the container.
docker run --pull never -it ${REGISTRY_NAME}/${PROJECT_NAME}:${VAULT_VERSION}${TAG_SUFFIX} /usr/bin/vault version

read -p "Version check for ${PROJECT_NAME}:${VAULT_VERSION}: Press enter to continue"

docker tag ${REGISTRY_NAME}/${PROJECT_NAME}:${VAULT_VERSION}${TAG_SUFFIX} scan.connect.redhat.com/${VAULT_PID}/${PROJECT_NAME}:${VAULT_VERSION}${TAG_SUFFIX}

docker login -u unused scan.connect.redhat.com --password="${REGISTRY_KEY}"

docker push scan.connect.redhat.com/${VAULT_PID}/${PROJECT_NAME}:${VAULT_VERSION}${TAG_SUFFIX}
