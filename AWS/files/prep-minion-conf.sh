#!/bin/bash
echo "Generating Minion Config To Upload"
if [ -d .tmp/conf ]; then
    rm -rf .tmp/conf
fi
mkdir -p .tmp/conf

printf "id: packer-local-minion\n" > .tmp/conf/minion
printf "minion_id_caching: True\n" >> .tmp/conf/minion
printf "fileserver_backend:\n  - roots\n  - gitfs\n" >> .tmp/conf/minion
printf "gitfs_base: ${SALT_BRANCH}\n" >> .tmp/conf/minion
#printf "gitfs_remotes:\n  - https://github.com/saltstack/salt-jenkins.git\n" >> .tmp/conf/minion
printf "gitfs_remotes:\n  - https://github.com/s0undt3ch/salt-jenkins.git\n" >> .tmp/conf/minion
