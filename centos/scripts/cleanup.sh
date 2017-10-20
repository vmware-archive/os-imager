# Ensure that udev doesn't screw us with network device naming.
sudo rm -f /etc/udev/rules.d/70-persistent-net.rules

# adding OpenNebula Context
sudo yum install -y https://github.com/OpenNebula/addon-context-linux/releases/download/v5.0.3/one-context_5.0.3.rpm
yum install -y epel-release
yum install ruby -y 
yum install -i dracut-modules-growroot
dracut -f
# Clean up unneeded packages.
sudo yum -y clean all
