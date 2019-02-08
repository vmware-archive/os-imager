#!/bin/bash

dir=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)

# Clone State Tree
. ${dir}/clone-salt-jenkins.sh

if [ ! -d .tmp/scripts ]; then
    mkdir -p .tmp/scripts
fi

dpath=".tmp/scripts/get-settings.psm1"
if [ ! -f "$dpath" ]; then
    curl -L https://github.com/saltstack/salt/raw/${SALT_BRANCH}/pkg/windows/modules/get-settings.psm1 --output $dpath
fi

if [ ! -d .tmp/pillar ]; then
    mkdir -p .tmp/pillar
fi

python_dir=$(grep Python${PY_VERSION}Dir .tmp/scripts/get-settings.psm1 | awk '{ print $3 }' | sed s/\"//g)
if [ "x${python_dir}" == "x" ]; then
    echo "Failed to parse the python path"
    exit 1
fi

echo "Building Pillar Data for Python Version: ${PY_VERSION}"
printf "base:\n  '*':\n    - python-target-version\n    - windows" > .tmp/pillar/top.sls
printf "py$PY_VERSION: true\n" > .tmp/pillar/python-target-version.sls
printf "virtualenv_path: ${python_dir}\\Scripts\\pip.exe\n" > .tmp/pillar/windows.sls
