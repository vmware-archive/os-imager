#!/bin/bash

dir=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)

. ${dir}/prep-minion-conf.sh
. ${dir}/prep-states.sh
. ${dir}/prep-pillar.sh
printf "    - windows\n" >> .tmp/pillar/top.sls
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

# Download the powershell script that installs Git on windows
curl -L https://github.com/tomlarse/Install-Git/raw/master/Install-Git/Install-Git.ps1 --output .tmp/scripts/Install-Git.ps1
