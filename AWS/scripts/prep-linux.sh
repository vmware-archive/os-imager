#!/bin/bash

dir=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)

# Clone State Tree
. ${dir}/clone-salt-jenkins.sh

if [ ! -d .tmp/pillar ]; then
    mkdir -p .tmp/pillar
fi

echo "Building Pillar Data for Python Version: ${PY_VERSION}"
printf "base:\n  '*':\n    - base\n" > .tmp/pillar/top.sls
printf "py$PY_VERSION: true\n" > .tmp/pillar/base.sls
printf "packer_build: true\n" >> .tmp/pillar/base.sls
printf "create_testing_dir: false\n" >> .tmp/pillar/base.sls
