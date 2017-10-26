# Ensure that udev doesn't screw us with network device naming.
sudo rm -f /etc/udev/rules.d/70-persistent-net.rules

# Clean up unneeded packages.
sudo yum -y clean all
