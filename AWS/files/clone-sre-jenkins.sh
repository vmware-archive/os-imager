#!/bin/bash
dir=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)

GPG_KEY="$(cd ${dir}; cd ../..; echo $(pwd)/gpgkey.asc)"
PRIVATE_KEY="$(cd ${dir}; cd ../..; echo $(pwd)/sre-jenkins-key)"
SRE_JENKINS_REPO="git@github.com:saltstack/sre-jenkins.git"
SRE_JENKINS_BRANCH="develop"
SRE_JENKINS_DIR=".tmp/${DISTRO_SLUG}/sre-jenkins"

if [ ! -f ${PRIVATE_KEY} ]; then
    echo "Please download the SSH private key from 1password named 'OS-Imager sre-jenkins RO SSH Private Key' and place it at ${PRIVATE_KEY}"
    exit 1
fi

if [ ! -f ${GPG_KEY} ]; then
    echo "Please download the operations GPG key from 1password and place it at ${GPG_KEY}"
    exit 1
fi

if [ -d ${SRE_JENKINS_DIR} ]; then
    rm -rf ${SRE_JENKINS_DIR}
fi

ssh-agent bash -c "ssh-add ${PRIVATE_KEY}; git clone --branch ${SRE_JENKINS_BRANCH} ${SRE_JENKINS_REPO} ${SRE_JENKINS_DIR}"
