#!/bin/bash
set -e

echo '==> install base-devel'
pacman -Syu base-devel --noconfirm --needed

echo '==> install cower'
curl -L https://aur.archlinux.org/cgit/aur.git/snapshot/cower.tar.gz | tar -C / -xzf -
pushd cower
chown -R salt.salt .
sudo -u salt makepkg -si --noconfirm --skipinteg --skippgpcheck
popd

cower -ddf yum
echo '==> install yum dependencies'
for pkg in rpm-org yum-metadata-parser python2-pyliblzma yum; do
    pushd $pkg
    echo "==> install $pkg"
    chown -R salt.salt .
    [[ $pkg == yum ]] && sed -i '/yum.patch/d' PKGBUILD && sudo -u salt updpkgsums
    sudo -u salt makepkg -si --noconfirm --skipinteg --skippgpcheck
    popd
done

cat > /etc/yum/repos.d/amzn-main.repo <<EOF
[amzn-main]
name=amzn-main-Base
mirrorlist=http://repo.us-west-1.amazonaws.com/latest/main/mirror.list
mirrorlist_expire=300
metadata_expire=300
priority=10
failovermethod=priority
fastestmirror_enabled=0
gpgcheck=0
enabled=1
retries=3
timeout=5
report_instanceid=yes
[amzn-updates]
name=amzn-updates-Base
mirrorlist=http://repo.us-west-1.amazonaws.com/latest/updates/mirror.list
mirrorlist_expire=300
metadata_expire=300
priority=10
failovermethod=priority
fastestmirror_enabled=0
gpgcheck=0
enabled=1
retries=3
timeout=5
report_instanceid=yes
EOF

if [[ $PACKER_BUILDER_TYPE == "qemu" ]]; then
	DISK='/dev/vda'
else
	DISK='/dev/sda'
fi

FQDN='amazon.saltstack.net'
KEYMAP='us'
LANGUAGE='en_US.UTF-8'
PASSWORD=$(/usr/bin/openssl passwd -crypt 'salt')
TIMEZONE='MST7MDT'

CONFIG_SCRIPT='/usr/local/bin/amazon-config.sh'
ROOT_PARTITION="${DISK}1"
TARGET_DIR='/mnt'
COUNTRY=${COUNTRY:-US}

echo "==> Clearing partition table on ${DISK}"
/usr/bin/sgdisk --zap ${DISK}

echo "==> Destroying magic strings and signatures on ${DISK}"
/usr/bin/dd if=/dev/zero of=${DISK} bs=512 count=2048
/usr/bin/wipefs --all ${DISK}

echo "==> Creating /root partition on ${DISK}"
/usr/bin/sgdisk --new=1:0:0 ${DISK}

echo "==> Setting ${DISK} bootable"
/usr/bin/sgdisk ${DISK} --attributes=1:set:2

echo '==> Creating /root filesystem (ext4)'
/usr/bin/mkfs.ext4 -O ^64bit -F -m 0 -q -L root ${ROOT_PARTITION}

echo "==> Mounting ${ROOT_PARTITION} to ${TARGET_DIR}"
/usr/bin/mount -o noatime,errors=remount-ro ${ROOT_PARTITION} ${TARGET_DIR}

echo '==> Bootstrapping the base installation'
yum install -y --installroot=/mnt system-release basesystem filesystem yum bash openssh syslinux sysvinit upstart
/usr/bin/sed -i "s|sda3|${ROOT_PARTITION##/dev/}|" "${TARGET_DIR}/boot/syslinux/syslinux.cfg"
/usr/bin/sed -i 's/TIMEOUT 50/TIMEOUT 10/' "${TARGET_DIR}/boot/syslinux/syslinux.cfg"

cat <<-EOF > "${TARGET_DIR}${CONFIG_SCRIPT}"
	echo '${FQDN}' > /etc/hostname
	/usr/bin/ln -sf /usr/share/zoneinfo/${TIMEZONE} /etc/localtime
	echo 'KEYMAP=${KEYMAP}' > /etc/vconsole.conf
	/usr/bin/sed -i 's/#${LANGUAGE}/${LANGUAGE}/' /etc/locale.gen
	/usr/bin/locale-gen
	/usr/bin/usermod --password ${PASSWORD} root
    cat > /etc/sysconfig/network-scripts/ifcfg-eth0 <<HERE
DEVICE=eth0
BOOTPROTO=dhcp
ONBOOT=yes
TYPE=Ethernet
USERCTL=yes
PEERDNS=yes
DHCPV6C=yes
DHCPV6C_OPTIONS=-nw
PERSISTENT_DHCLIENT=yes
RES_OPTIONS="timeout:2 attempts:5"
DHCP_ARP_CHECK=no
HERE
	/usr/bin/sed -i 's/#UseDNS yes/UseDNS no/' /etc/ssh/sshd_config
    chkconfig sshd on
    /usr/bin/useradd --password ${PASSWORD} --comment 'Salt User' --create-home --user-group salt
	echo 'Defaults env_keep += "SSH_AUTH_SOCK"' > /etc/sudoers.d/10_salt
	echo 'salt ALL=(ALL) NOPASSWD: ALL' >> /etc/sudoers.d/10_salt
	/usr/bin/chmod 0440 /etc/sudoers.d/10_salt

    echo '==> Add OpenNebula context stuff'
    yum install -y epel-release https://github.com/OpenNebula/addon-context-linux/releases/download/v5.0.3/one-context_5.0.3.rpm
    yum install ruby -y 
    yum install -i dracut-modules-growroot
    dracut -f
    chkconfig vmcontext on
EOF

echo '==> Entering chroot and configuring system'
/usr/bin/arch-chroot ${TARGET_DIR} ${CONFIG_SCRIPT}
rm -rf "${TARGET_DIR}${CONFIG_SCRIPT}" "${TARGET_DIR}/context" "${TARGET_DIR}/mkinitcpio-growrootfs/"

echo '==> Installation complete!'
/usr/bin/sleep 3
/usr/bin/umount ${TARGET_DIR}
