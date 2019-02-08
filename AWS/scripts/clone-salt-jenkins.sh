#!/bin/bash

if [ ! -d .tmp/states ]; then
    mkdir -p .tmp/states
fi

if [ -d .tmp/states/.git ]; then
    echo "Resetting git branch to ${SALT_BRANCH}"
    git -C .tmp/states fetch
    git -C .tmp/states reset --hard origin/$SALT_BRANCH
else
    echo "Cloning salt-jenkins repository. Branch: ${SALT_BRANCH}"
    git clone --branch $SALT_BRANCH https://github.com/saltstack/salt-jenkins.git .tmp/states
fi
