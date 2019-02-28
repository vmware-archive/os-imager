#!/bin/bash

dir=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)

curl -L https://github.com/tomlarse/Install-Git/raw/master/Install-Git/Install-Git.ps1 --output .tmp/scripts/Install-Git.ps1

echo "Building Minimal State Tree For Windows"
if [ ! -d .tmp/win_states ]; then
    mkdir -p .tmp/win_states
fi
#printf "'*':\n  - empty\n" > .tmp/win_states/top.sls
printf "noop:\n  test.succeed_without_changes" > .tmp/win_states/empty.sls

echo "Building Pillar Data for Python Version: ${PY_VERSION}"
if [ ! -d .tmp/pillar ]; then
    mkdir -p .tmp/pillar
fi
printf "base:\n  '*':\n    - base\n    - windows\n" > .tmp/pillar/top.sls
printf "py$PY_VERSION: true\n" > .tmp/pillar/base.sls
printf "packer_build: true\n" >> .tmp/pillar/base.sls
printf "create_testing_dir: false\n" >> .tmp/pillar/base.sls
if [ "$PY_VERSION" -eq 2 ]; then
    PYTHON_DIR="C:\\Python27"
elif [ "$PY_VERSION" -eq 3 ]; then
    PYTHON_DIR="C:\\Python35"
else
    echo "Don't know how to hanle PY_VERSION $PY_VERSION"
    exit 1
fi
printf "python_install_dir: ${PYTHON_DIR}\n" > .tmp/pillar/windows.sls
printf "virtualenv_path: ${PYTHON_DIR}\\Scripts\\pip.exe\n" >> .tmp/pillar/windows.sls

echo "Geneating Minion Config To Upload"
if [ ! -d .tmp/conf ]; then
    mkdir -p .tmp/conf
fi

printf "fileserver_backend:\n  - gitfs\n  - roots\n" > .tmp/conf/minion
printf "gitfs_base: ${SALT_BRANCH}\n" >> .tmp/conf/minion
printf "gitfs_remotes:\n  - https://github.com/s0undt3ch/salt-jenkins.git\n" >> .tmp/conf/minion
