#!/bin/bash

# If this is not a pre-release, we determine if any of the 'latest' images need to be updated

function main() {
   
   if [[ "${DOCKER_TAG}" =~ [0-9]+\.[0-9]+\.[0-9]+$ ]]; then
      # check to see if the current tag is higher than the latest version on dockerhub
      HIGHER_LATEST_VERSION=$(higher_version "$DOCKER_TAG" "$LATEST_DOCKER_VERSION")
      echo "Docker tag is: $DOCKER_TAG"
      echo "Latest tag is: $LATEST_DOCKER_VERSION"
      echo "Higher version is: $HIGHER_LATEST_VERSION"
      # if:
      #   * we didn't find a version from the 'latest' image, it means it doesn't exist
      #   * or if the current tag version is higher than the latest docker one (or the same)
      # we build latest
      if [ -z "$LATEST_DOCKER_VERSION" ] || [ "$HIGHER_LATEST_VERSION" = "$DOCKER_TAG" ]; then
         echo "Tagging a new latest docker image"
         docker tag "$DOCKER_ORG"/"$PROJECT_NAME":"$DOCKER_TAG" "$DOCKER_ORG"/"$PROJECT_NAME":latest || return 1
         docker push "$DOCKER_ORG"/"$PROJECT_NAME":latest || return 1
      fi
   fi
   # If it is a prerelease, we don't tag latest so we do nothing here

   return 0
}
main "$@"
exit $?