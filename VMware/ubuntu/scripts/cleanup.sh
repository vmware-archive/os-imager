#!/bin/bash -eux

# Enable verbose boot
sed -i 's/ quiet//g' /etc/default/grub
sed -i 's/quiet //g' /etc/default/grub
sed -i 's/quiet//g' /etc/default/grub
sed -i 's/ splash//g' /etc/default/grub
sed -i 's/splash //g' /etc/default/grub
sed -i 's/splash//g' /etc/default/grub
update-grub

# see https://kb.vmware.com/s/article/56409

sed -i 's#^D /tmp #d /tmp #' /usr/lib/tmpfiles.d/tmp.conf
mkdir -p /etc/systemd/system/open-vm-tools.service.d
cat > /etc/systemd/system/open-vm-tools.service.d/local.conf <<EOF
[Unit]
After=dbus.service
EOF

sed -i 's/auto eth0/allow-hotplug eth0/g' /etc/network/interfaces

echo "==> Cleaning up unneeded apt files"
apt-get -y autoremove --purge
apt-get -y clean
apt-get -y autoclean
rm -rf /var/lib/apt/lists/*

echo "==> Installing rc.local to setup VM on first boot"
mv -f /etc/rc.local /etc/rc.local.orig
cat > /etc/rc.local <<EOF
#!/bin/bash
rm -f /etc/machine-id
rm -f /var/lib/dbus/machine-id
systemd-machine-id-setup
cp -af /etc/machine-id /var/lib/dbus/machine-id
rm -f /etc/ssh/*_key*
ssh-keygen -q -t rsa -f /etc/ssh/ssh_host_rsa_key -C '' -N ''
ssh-keygen -q -t ecdsa -f /etc/ssh/ssh_host_ecdsa_key -C '' -N ''
ssh-keygen -q -t ed25519 -f /etc/ssh/ssh_host_ed25519_key -C '' -N ''
sed -i 's#^d /tmp #D /tmp #' /usr/lib/tmpfiles.d/tmp.conf
rm -f /etc/rc.local
mv -f /etc/rc.local.orig /etc/rc.local
EOF
chmod +x /etc/rc.local

echo "==> Cleaning up leftover dhcp leases"
if [ -d "/var/lib/dhcp" ]; then
    rm /var/lib/dhcp/*
fi

echo "==> Clearing last login information"
>/var/log/lastlog
>/var/log/wtmp
>/var/log/btmp

echo "==> Cleaning up tmp"
rm -rf /tmp/*

# Remove Bash history
unset HISTFILE
rm -f /root/.bash_history
rm -f /home/*/.bash_history
