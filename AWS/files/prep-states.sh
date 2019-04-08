#!/bin/bash

echo "Building Minimal State Tree"
if [ -d .tmp/${SALT_BRANCH}/states ]; then
    rm -rf .tmp/${SALT_BRANCH}/states
fi
mkdir -p .tmp/${SALT_BRANCH}/states

printf "noop:\n  test.succeed_without_changes" > .tmp/${SALT_BRANCH}/states/empty.sls
