##!/bin/bash
set -xe

# TAG=latest for prod, TAG=staging for staging (default)

if [ -z "${TAG}" ]; then
    TAG=staging
fi

if [ ! -z "${NETWORK}" ]; then
    DOCKER_OPTS="--network=${NETWORK}"
fi

nix build ".#${TAG}"
./result | docker load
docker push docker.lan:5000/dev-env:${TAG}
rm result
