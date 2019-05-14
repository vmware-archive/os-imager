#!/bin/bash

echo "Building Minimal State Tree"
if [ -d .tmp/${DISTRO_SLUG}/${SALT_BRANCH}/states ]; then
    rm -rf .tmp/${DISTRO_SLUG}/${SALT_BRANCH}/states
fi
mkdir -p .tmp/${DISTRO_SLUG}/${SALT_BRANCH}/states

printf "noop:\n  test.succeed_without_changes" > .tmp/${DISTRO_SLUG}/${SALT_BRANCH}/states/empty.sls
