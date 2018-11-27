#!/bin/bash -eux

# From https://github.com/boxcutter/debian/blob/master/script/cleanup.sh

CLEANUP_PAUSE=${CLEANUP_PAUSE:-0}
echo "==> Pausing for ${CLEANUP_PAUSE} seconds..."
sleep ${CLEANUP_PAUSE}

# Unique SSH keys will be generated on first boot
echo "==> Removing SSH server keys"
rm -f /etc/ssh/*_key*

# Unique machine ID will be generated on first boot
echo "==> Removing machine ID"
rm -f /etc/machine-id
rm -f /var/lib/dbus/machine-id

# Make sure Udev doesn't block our network
# http://6.ptmc.org/?p=164
echo "cleaning up udev rules"
rm -rf /dev/.udev/
rm /lib/udev/rules.d/75-persistent-net-generator.rules

echo "==> Cleaning up leftover dhcp leases"
if [ -d "/var/lib/dhcp" ]; then
    rm /var/lib/dhcp/*
fi

echo "==> Cleaning up tmp"
rm -rf /tmp/*

# Cleanup apt cache
apt-get -y autoremove --purge
apt-get -y clean
apt-get -y autoclean

echo "==> Installed packages"
dpkg --get-selections | grep -v deinstall

# Remove Bash history
unset HISTFILE
rm -f /root/.bash_history
rm -f /home/vagrant/.bash_history

# Clean up log files
echo "==> Purging log files"
find /var/log -type f -delete

# fix for debian 8 https://projects.archlinux.org/svntogit/packages.git/commit/trunk?h=packages/systemd&id=17b104865a0653703e447275e6d2169c69040f3e
# ***systemd issue***
# install gawk to parse dist
apt-get install -y gawk
# run check to make sure its debian 8 only.
COMMAND=$(lsb_release -d | gawk -F'\t' '{print $2}')

if [ "$COMMAND" == "Debian GNU/Linux 8.9 (jessie)" ]; then
  apt-get install -y uuid-runtime
  uuidgen | { read; echo "${REPLY//-}">/etc/machine-id; }
else
  echo "Not Debian 8 exiting..."
fi

# Skipping the whiteout part from box-cutter -- which would just fill up the qcow2 image

# # Whiteout root
# count=$(df --sync -kP / | tail -n1  | awk -F ' ' '{print $4}')
# let count--
# dd if=/dev/zero of=/tmp/whitespace bs=1024 count=$count
# rm /tmp/whitespace

# # Whiteout /boot
# count=$(df --sync -kP /boot | tail -n1 | awk -F ' ' '{print $4}')
# let count--
# dd if=/dev/zero of=/boot/whitespace bs=1024 count=$count
# rm /boot/whitespace

# # Zero out the free space to save space in the final image
# dd if=/dev/zero of=/EMPTY bs=1M
# rm -f /EMPTY

# Make sure we wait until all the data is written to disk, otherwise
# Packer might quite too early
# sync
