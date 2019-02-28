#!/bin/bash

echo "Building Minimal State Tree"
if [ -d .tmp/states ]; then
    rm -rf .tmp/states
fi
mkdir -p .tmp/states

printf "noop:\n  test.succeed_without_changes" > .tmp/states/empty.sls
