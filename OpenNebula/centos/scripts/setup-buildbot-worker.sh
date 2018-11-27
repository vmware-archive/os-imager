#!/bin/bash

# Disable SELINUX
sudo sed -i 's/^SELINUX=\(.*\)$/SELINUX=disabled/g' /etc/sysconfig/selinux

# Upgrade the system packages to latest
sudo yum update -y

# Install and close all access to the machine except SSH
sudo yum install -y firewalld
sudo systemctl enable firewalld
sudo systemctl start firewalld
sudo firewall-cmd --permanent --add-service=ssh

# Disable root logins
sudo sed -i 's/#PermitRootLogin yes/PermitRootLogin no/g' /etc/ssh/sshd_config
sudo systemctl enable sshd.service

# Docker
sudo yum install -y yum-utils epel-release
sudo yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
sudo yum install -y docker-ce
sudo systemctl enable docker.service
sudo systemctl start docker.service

# Enable docker experimental features
cat << EOF > /tmp/docker-daemon.json
{
  "experimental": true
}
EOF

sudo mv /tmp/docker-daemon.json /etc/docker/daemon.json
sudo systemctl restart docker.service

# Python 3
sudo yum -y install https://centos7.iuscommunity.org/ius-release.rpm || exit 1
sudo yum install -y python35u-pip || exit 1
sudo pip3.5 install -U pip virtualenv || exit 1
sudo mv /usr/bin/virtualenv /usr/bin/virtualenv-3 || exit 1

# Python 2
sudo yum install -y python2-pip python2-devel gcc jq git
sudo pip2 install -U pip
sudo pip2 install -U virtualenv

# Buildbot User & Group
sudo groupadd -g 10000 buildbot
sudo useradd -m -u 10000 -g buildbot -s /bin/bash -d /var/lib/buildbot buildbot
echo "%buildbot ALL=(ALL) NOPASSWD: ALL" >> /tmp/buildbot-sudoers
sudo chown root:root /tmp/buildbot-sudoers
sudo chmod 0440 /tmp/buildbot-sudoers
sudo mv /tmp/buildbot-sudoers /etc/sudoers.d/buildbot
sudo gpasswd -a buildbot docker
sudo mkdir -p /var/lib/buildbot/.ssh
sudo mkdir -p /var/lib/buildbot/.aws
sudo chown -R centos /var/lib/buildbot
sudo chmod 700 /var/lib/buildbot/.ssh
sudo chmod 700 /var/lib/buildbot/.aws

virtualenv --unzip-setuptools /var/lib/buildbot/.venv
source /var/lib/buildbot/.venv/bin/activate
pip install -U buildbot-worker awscli
deactivate

cat << EOF > /tmp/buildbot-worker.service
[Unit]
Description=BuildBot Worker Service
After=network.target

[Service]
User=buildbot
Group=buildbot
WorkingDirectory=/var/lib/buildbot/buildbot-worker
Environment="VIRTUAL_ENV=/var/lib/buildbot/.venv PATH=/var/lib/buildbot/.venv/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin"
ExecStart=/var/lib/buildbot/.venv/bin/buildbot-worker start --nodaemon
Restart=always

[Install]
WantedBy=multi-user.target
EOF

sudo mv /tmp/buildbot-worker.service /lib/systemd/system/buildbot-worker.service

sudo chown -R buildbot:buildbot /var/lib/buildbot


# Cleanup
sudo rm -rf /tmp/* /home/centos/.cache /var/lib/buildbot/.cache
sudo yum clean all
sudo rm -rf /var/cache/yum
sudo find /var/log -type f -exec truncate -s 0 {} \;
