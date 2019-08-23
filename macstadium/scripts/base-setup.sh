#!/bin/bash

OSX_VERS=$(sw_vers -productVersion | awk -F "." '{print $2}')

echo "==> Turn off hibernation"
pmset hibernatemode 0

echo "==> Get rid of the sleepimage"
rm -f /var/vm/sleepimage

echo "==> Disable power saving"
pmset -a displaysleep 0 disksleep 0 sleep 0

echo "==> Disable screensaver"
defaults -currentHost write com.apple.screensaver idleTime 0

echo "==> Clear cache"
rm -rf /Users/vagrant/Library/Caches/* \
    /Library/Caches/*

echo "==> Clear bash history"
rm /Users/vagrant/.bash_history

echo "==> Clear logs"
rm -rf /private/var/log/*

echo "==> Clear temporary files"
rm -rf /tmp/*

echo "==> Stop the page process and dropping swap files"
# These will be re-created on boot
# Starting with El Cap we can only stop the dynamic pager if SIP is disabled.
if [ "$OSX_VERS" -lt 11 ] || $(csrutil status | grep -q disabled); then
    launchctl unload /System/Library/LaunchDaemons/com.apple.dynamic_pager.plist
    sleep 5
fi
rm -rf /private/var/vm/swap*

slash="$(df -h / | tail -n 1 | awk '{print $1}')"

echo "==> Zeroing out free space"
diskutil secureErase freespace 0 ${slash}
