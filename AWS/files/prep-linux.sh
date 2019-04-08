#!/bin/bash

dir=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)

# Clone State Tree
. ${dir}/prep-minion-conf.sh
. ${dir}/prep-states.sh
. ${dir}/prep-pillar.sh

echo "Copying gitpython.sls to the temp states directory"
cp ${dir}/gitpython.sls .tmp/${SALT_BRANCH}/states/
ls -lah .tmp/${SALT_BRANCH}/states
