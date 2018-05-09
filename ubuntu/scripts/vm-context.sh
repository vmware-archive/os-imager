# install open nebula vm context
wget https://github.com/OpenNebula/addon-context-linux/releases/download/v5.0.3/one-context_5.0.3.deb
dpkg -i one-context*deb
apt-get install -y ruby # only needed for onegate command
apt-get install -y cloud-utils
