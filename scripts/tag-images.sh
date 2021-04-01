#!/bin/bash

#    * VERSION - Image version to tag i.e 1.7.0 or 1.7.0-
#	  * REGISTRY_NAME - Docker Registry Name i.e docker.io/hashicorp
#	  * PROJECT_NAME - Project name i.e vault or vault-enterprise

# Introspects the docker label of an container to see what version 'latest' is
function get_latest_docker_version() {
   # Arguments:
   #   $1 - Docker Org
   #   $2 - Docker Image Name
   #
   #
   # Returns:
   #   0 - success (version in the 'latest' container echoed)
   #   1 - 'latest' tag does not exist or label could not be found

   docker pull "$1"/"$2":latest
   local docker_latest=$(docker inspect --format="{{ index .Config.Labels.version }}" "$1"/"$2":latest)
   if [ -z "$docker_latest" ]; then
      return 1
   else
      echo "$docker_latest"
      return 0
   fi
}

# Calculates the higher of two versions
function higher_version() {
   # Arguments:
   #   $1 - first version to compare
   #   $2 - second version to compare
   #
   # Returns:
   #   higher version of two arguments

   higher_version=$(echo -e "$1\n$2" | sort -rV | head -n 1)
   echo "$higher_version"
}

# If this is not a pre-release, we determine if any of the 'latest' images need to be updated
function main() {

   : "${VERSION?"Need to set VERSION"}"

   : "${REGISTRY_NAME?"Need to set REGISTRY_NAME"}"

   : "${PROJECT_NAME?"Need to set PROJECT_NAME"}"

   DOCKER_TAG="$VERSION$TAG_SUFFIX"

   if [[ "${VERSION}" =~ [0-9]+\.[0-9]+\.[0-9]+$ ]]; then
      echo "Tagging a new latest docker image"
      docker tag "$REGISTRY_NAME"/"$PROJECT_NAME":"$DOCKER_TAG" "$REGISTRY_NAME"/"$PROJECT_NAME":latest || return 1
   fi
   # If it is a prerelease, we don't tag latest so we do nothing here

   return 0
}
main "$@"
exit $?
