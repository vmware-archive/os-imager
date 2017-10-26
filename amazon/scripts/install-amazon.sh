#!/bin/bash
set -e

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
BOOT_PARTITION="${DISK}1"
ROOT_PARTITION="${DISK}2"
TARGET_DIR='/mnt'
COUNTRY=${COUNTRY:-US}

if ! getent passwd salt; then
	echo '==> adding salt users'
	useradd -m salt
	echo 'salt ALL=(ALL) NOPASSWD: ALL' >> /etc/sudoers
fi

echo "==> Clearing partition table on ${DISK}"
/usr/bin/sgdisk --zap ${DISK}

echo "==> Destroying magic strings and signatures on ${DISK}"
/usr/bin/dd if=/dev/zero of=${DISK} bs=512 count=2048
/usr/bin/wipefs --all ${DISK}

echo "==> Creating /root partition on ${DISK}"
/usr/bin/sgdisk --new=1:0:+200M ${DISK}
/usr/bin/sgdisk --new=2:0:0 ${DISK}

echo "==> Setting ${DISK} bootable"
/usr/bin/sgdisk ${DISK} --attributes=1:set:2

echo "==> Creating /boot filesystem (fat)"
/usr/bin/mkfs -t ext3 "${BOOT_PARTITION}"

echo '==> Creating /root filesystem (ext4)'
/usr/bin/mkfs -t ext4 -O ^64bit -F -m 0 -q -L root ${ROOT_PARTITION}

echo "==> Mounting ${ROOT_PARTITION} to ${TARGET_DIR}"
/usr/bin/mount -o noatime,errors=remount-ro ${ROOT_PARTITION} ${TARGET_DIR}
mkdir "${TARGET_DIR}"/{boot,dev,proc,sys}
mount "${BOOT_PARTITION}" "${TARGET_DIR}/boot"
for device in dev proc sys; do
	mount -o rbind /$device /mnt/$device
done

echo '==> updating archlinux-keyring'
pacman -Sy --noconfirm archlinux-keyring

echo '==> install base-devel'
pacman -Syu base-devel --noconfirm --needed --ignore linux

echo '==> install cower'
curl -L https://aur.archlinux.org/cgit/aur.git/snapshot/cower.tar.gz | tar -C / -xzf -
pushd /cower
chown -R salt.salt .
sudo -u salt makepkg -si --noconfirm --skipinteg --skippgpcheck
popd

echo '==> install yum'
cower -t / -ddf yum
echo '==> install yum dependencies'
for pkg in rpm-org yum-metadata-parser python2-pyliblzma yum; do
	pushd /$pkg
	echo "==> install $pkg"
	chown -R salt.salt .
	[[ $pkg == yum ]] && sed -i '/yum.patch/d' PKGBUILD && sudo -u salt updpkgsums
	sudo -u salt makepkg -si --noconfirm --skipinteg --skippgpcheck
	popd
done

echo '==> Adding Repositories'
tee /etc/yum/repos.d/amzn-main.repo <<EOF
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

echo '==> Bootstrapping the base installation'
yum install -y --installroot=/mnt $(</pkgs.list)

echo '==> Generating the filesystem table'
/usr/bin/genfstab -p ${TARGET_DIR} >> "${TARGET_DIR}/etc/fstab"

cat <<-EOF > "${TARGET_DIR}${CONFIG_SCRIPT}"
	export PATH=/usr/local/bin:/bin:/usr/bin:/usr/local/sbin:/usr/sbin:/sbin:/opt/aws/bin:/bin:/home/ec2-user/.local/bin:/home/ec2-user/bin
	echo 'export PATH=/usr/local/bin:/bin:/usr/bin:/usr/local/sbin:/usr/sbin:/sbin:/opt/aws/bin:/bin:/home/ec2-user/.local/bin:/home/ec2-user/bin' > /etc/profile.d/01-paths.sh
	echo 'nameserver 8.8.8.8' > /etc/resolv.conf
	echo '${FQDN}' > /etc/hostname
	ln -sf /usr/share/zoneinfo/${TIMEZONE} /etc/localtime
	echo 'KEYMAP=${KEYMAP}' > /etc/vconsole.conf
	usermod --password ${PASSWORD} root
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
	sed -i 's/#UseDNS yes/UseDNS no/' /etc/ssh/sshd_config
	chkconfig sshd on
	useradd --password ${PASSWORD} --comment 'Salt User' --create-home --user-group salt
	echo 'Defaults env_keep += "SSH_AUTH_SOCK"' > /etc/sudoers.d/10_salt
	echo 'salt ALL=(ALL) NOPASSWD: ALL' >> /etc/sudoers.d/10_salt
	chmod 0440 /etc/sudoers.d/10_salt
	grub-install "${DISK}"
	yum install -y kernel irqbalance

	echo '==> Add OpenNebula context stuff'
	yum install -y epel-release https://github.com/OpenNebula/addon-context-linux/releases/download/v5.0.3/one-context_5.0.3.rpm ruby cloud-disk-utils
	chkconfig vmcontext on
EOF

echo '==> Entering chroot and configuring system'
chmod +x "${TARGET_DIR}/${CONFIG_SCRIPT}"
chroot ${TARGET_DIR} ${CONFIG_SCRIPT}
rm -f "${TARGET_DIR}${CONFIG_SCRIPT}"

echo '==> Installation complete!'
/usr/bin/sleep 3
