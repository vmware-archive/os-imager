#!/bin/bash

dir=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)

. ${dir}/prep-minion-conf.sh
. ${dir}/prep-states.sh
. ${dir}/prep-pillar.sh
printf "    - windows\n" >> .tmp/${SALT_BRANCH}/pillar/top.sls
if [ "$PY_VERSION" -eq 2 ]; then
    PYTHON_DIR="C:\\Python27"
elif [ "$PY_VERSION" -eq 3 ]; then
    PYTHON_DIR="C:\\Python35"
else
    echo "Don't know how to handle PY_VERSION $PY_VERSION"
    exit 1
fi
printf "python_install_dir: ${PYTHON_DIR}\n" > .tmp/${SALT_BRANCH}/pillar/windows.sls
printf "virtualenv_path: ${PYTHON_DIR}\\Scripts\\pip.exe\n" >> .tmp/${SALT_BRANCH}/pillar/windows.sls

# Download the powershell script that installs Git on windows
if [ ! -f .tmp/scripts/Install-Git.ps1 ] || [ ! -s .tmp/scripts/Install-Git.ps1 ]; then
    URL="https://github.com/tomlarse/Install-Git/raw/master/Install-Git/Install-Git.ps1"
    echo "Downloading ${URL}"
    curl -L $URL --output .tmp/scripts/Install-Git.ps1
fi
