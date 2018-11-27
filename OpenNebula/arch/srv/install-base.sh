#!/usr/bin/env bash

# stop on errors
set -eu

DISK='/dev/vda'
FQDN='arch.saltstack.net'
KEYMAP='us'
LANGUAGE='en_US.UTF-8'
PASSWORD=$(/usr/bin/openssl passwd -crypt 'salt')
TIMEZONE='MST7MDT'

CONFIG_SCRIPT='/usr/local/bin/arch-config.sh'
ROOT_PARTITION="${DISK}1"
TARGET_DIR='/mnt'
COUNTRY=${COUNTRY:-US}
MIRRORLIST="https://www.archlinux.org/mirrorlist/?country=${COUNTRY}&protocol=http&protocol=https&ip_version=4&use_mirror_status=on"

echo "==> Setting local mirror"
curl -s "$MIRRORLIST" |  sed 's/^#Server/Server/' > /etc/pacman.d/mirrorlist

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
/usr/bin/pacstrap ${TARGET_DIR} base base-devel
/usr/bin/arch-chroot ${TARGET_DIR} pacman -S --noconfirm gptfdisk openssh syslinux ruby
/usr/bin/arch-chroot ${TARGET_DIR} syslinux-install_update -i -a -m
/usr/bin/sed -i "s|sda3|${ROOT_PARTITION##/dev/}|" "${TARGET_DIR}/boot/syslinux/syslinux.cfg"
/usr/bin/sed -i 's/TIMEOUT 50/TIMEOUT 10/' "${TARGET_DIR}/boot/syslinux/syslinux.cfg"

echo '==> Generating the filesystem table'
/usr/bin/genfstab -p ${TARGET_DIR} >> "${TARGET_DIR}/etc/fstab"

echo '==> Generating the system configuration script'
/usr/bin/install --mode=0755 /dev/null "${TARGET_DIR}${CONFIG_SCRIPT}"

echo '==> Copy OneContext PKGBUILD to root'
/usr/bin/mkdir "${TARGET_DIR}/context"
/usr/bin/install --mode=0644 /PKGBUILD "${TARGET_DIR}/context/PKGBUILD"

cat <<-EOF > "${TARGET_DIR}${CONFIG_SCRIPT}"
	echo '${FQDN}' > /etc/hostname
	/usr/bin/ln -sf /usr/share/zoneinfo/${TIMEZONE} /etc/localtime
	echo 'KEYMAP=${KEYMAP}' > /etc/vconsole.conf
	/usr/bin/sed -i 's/#${LANGUAGE}/${LANGUAGE}/' /etc/locale.gen
	/usr/bin/locale-gen
	/usr/bin/usermod --password ${PASSWORD} root
	# https://wiki.archlinux.org/index.php/Network_Configuration#Device_names
	/usr/bin/ln -sf /dev/null /etc/udev/rules.d/80-net-setup-link.rules
	/usr/bin/ln -sf '/usr/lib/systemd/system/dhcpcd@.service' '/etc/systemd/system/multi-user.target.wants/dhcpcd@eth0.service'
	/usr/bin/sed -i 's/#UseDNS yes/UseDNS no/' /etc/ssh/sshd_config
	/usr/bin/sed -i 's/#PermitRootLogin without-password/PermitRootLogin yes/' /etc/ssh/sshd_config
	/usr/bin/systemctl enable sshd.service
    /usr/bin/useradd --password ${PASSWORD} --comment 'Salt User' --create-home --user-group salt
	echo 'Defaults env_keep += "SSH_AUTH_SOCK"' > /etc/sudoers.d/10_salt
	echo 'salt ALL=(ALL) NOPASSWD: ALL' >> /etc/sudoers.d/10_salt
	/usr/bin/chmod 0440 /etc/sudoers.d/10_salt

    echo '===> Installing OpenNebula Stuff'
    echo '===> mkinitcpio-growrootfs'
    sed -i 's:^PRESETS.*:PRESETS=(default):' /etc/mkinitcpio.d/linux.preset
    sed -i 's:filesystems:& growfs:' /etc/mkinitcpio.conf
    curl -L https://aur.archlinux.org/cgit/aur.git/snapshot/mkinitcpio-growrootfs.tar.gz | tar -C / -xzf -
    cd /mkinitcpio-growrootfs/
    chown -R salt:salt .
    sudo -u salt makepkg -si --noconfirm

    echo '===> context'
    cd /context
    chown -R salt:salt .
    sudo -u salt makepkg -sic --noconfirm
    systemctl enable -f one-context.service

	# clean up
	/usr/bin/pacman -Rcns --noconfirm gptfdisk
EOF

echo '==> Entering chroot and configuring system'
/usr/bin/arch-chroot ${TARGET_DIR} ${CONFIG_SCRIPT}
rm -rf "${TARGET_DIR}${CONFIG_SCRIPT}" "${TARGET_DIR}/context" "${TARGET_DIR}/mkinitcpio-growrootfs/"

echo '==> Installation complete!'
/usr/bin/sleep 3
/usr/bin/umount ${TARGET_DIR}
shutdown -r now
