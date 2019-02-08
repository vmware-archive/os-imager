#!/bin/bash

dir=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)

# Clone State Tree
. ${dir}/clone-salt-jenkins.sh

if [ ! -d .tmp/pillar ]; then
    mkdir -p .tmp/pillar
fi

echo "Building Pillar Data for Python Version: ${PY_VERSION}"
printf "base:\n  '*':\n    - python-target-version" > .tmp/pillar/top.sls
printf "py$PY_VERSION: true\n" > .tmp/pillar/python-target-version.sls
