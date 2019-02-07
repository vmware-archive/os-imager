# Enable verbose boot
sed -i 's/ quiet//g' /etc/default/grub
sed -i 's/quiet //g' /etc/default/grub
sed -i 's/quiet//g' /etc/default/grub
sed -i 's/ splash//g' /etc/default/grub
sed -i 's/splash //g' /etc/default/grub
sed -i 's/splash//g' /etc/default/grub
sed -i 's/ rhgb//g' /etc/default/grub
sed -i 's/rhgb //g' /etc/default/grub
sed -i 's/rhgb//g' /etc/default/grub
grub2-mkconfig -o "$(readlink -f /etc/grub2.cfg 2>/dev/null)"

# Send host name with dhcp request
echo "send host-name = gethostname();" >> /etc/dhcp/dhclient.conf

# Regsiter with redhat
subscription-manager register --username "${RHEL_USERNAME}" --password "${RHEL_PASSWORD}" --auto-attach

echo "==> Cleaning up unneeded yum files and updating"
sudo yum -y update
sudo yum -y clean all

echo "==> Installing rc.local to setup VM on first boot"
mv -f /etc/rc.d/rc.local /etc/rc.d/rc.local.orig
cat > /etc/rc.d/rc.local <<EOF
#!/bin/bash
rm -f /etc/machine-id
systemd-machine-id-setup
rm -f /etc/ssh/*_key*
ssh-keygen -q -t rsa -f /etc/ssh/ssh_host_rsa_key -C '' -N ''
ssh-keygen -q -t ecdsa -f /etc/ssh/ssh_host_ecdsa_key -C '' -N ''
ssh-keygen -q -t ed25519 -f /etc/ssh/ssh_host_ed25519_key -C '' -N ''
rm -f /etc/rc.d/rc.local
mv -f /etc/rc.d/rc.local.orig /etc/rc.d/rc.local
EOF
chmod +x /etc/rc.d/rc.local

echo "==> Cleaning up leftover dhcp leases"
if [ -d "/var/lib/dhclient" ]; then
    rm /var/lib/dhclient/*
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
