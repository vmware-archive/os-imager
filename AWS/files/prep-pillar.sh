#!/bin/bash

echo "Building Pillar Data for Python Version: ${PY_VERSION}"
if [ -d .tmp/pillar ]; then
    rm -rf .tmp/pillar
fi
mkdir -p .tmp/pillar
printf "base:\n  '*':\n    - base\n" > .tmp/pillar/top.sls
printf "py$PY_VERSION: true\n" > .tmp/pillar/base.sls
printf "packer_build: true\n" >> .tmp/pillar/base.sls
printf "packer_golden_images_build: true\n" >> .tmp/pillar/base.sls
printf "create_testing_dir: false\n" >> .tmp/pillar/base.sls
