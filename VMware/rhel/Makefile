
.DEFAULT: all
.PHONY: all
all: rhel7-fips rhel8

.PHONY: rhel7-fips
rhel7-fips: output-rhel7-fips/rhel7-fips/rhel7-fips.ovf

output-rhel7-fips/rhel7-fips/rhel7-fips.ovf: rhel7-fips.json rhel.json kickstart/rhel7-fips.cfg scripts/cleanup.sh
	rm -rf output-rhel7-fips
	packer build -var-file=rhel7-fips.json rhel.json

.PHONY: rhel8
rhel8: output-rhel8/rhel8/rhel8.ovf

output-rhel8/rhel8/rhel8.ovf: rhel8.json rhel.json kickstart/rhel8.cfg scripts/cleanup.sh
	rm -rf output-rhel8
	packer build -var-file=rhel8.json rhel.json

.PHONY: clean
clean:
	rm -rf output*
