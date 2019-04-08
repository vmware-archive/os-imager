#!/bin/bash

echo "Building Pillar Data for Python Version: ${PY_VERSION}"
if [ -d .tmp/${SALT_BRANCH}/pillar ]; then
    rm -rf .tmp/${SALT_BRANCH}/pillar
fi
mkdir -p .tmp/${SALT_BRANCH}/pillar
printf "base:\n  '*':\n    - base\n" > .tmp/${SALT_BRANCH}/pillar/top.sls
printf "py$PY_VERSION: true\n" > .tmp/${SALT_BRANCH}/pillar/base.sls
printf "packer_build: true\n" >> .tmp/${SALT_BRANCH}/pillar/base.sls
printf "packer_golden_images_build: true\n" >> .tmp/${SALT_BRANCH}/pillar/base.sls
printf "create_testing_dir: false\n" >> .tmp/${SALT_BRANCH}/pillar/base.sls
