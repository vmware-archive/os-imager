
.DEFAULT: all
.PHONY: all
all: rhel7-fips

.PHONY: rhel7-fips
rhel7-fips: output-rhel7-fips/rhel7-fips/rhel7-fips.ovf

output-rhel7-fips/rhel7-fips/rhel7-fips.ovf: rhel7-fips.json rhel.json kickstart/rhel7-fips.cfg scripts/cleanup.sh
	rm -rf output-rhel7-fips
	packer build -var-file=rhel7-fips.json rhel.json


.PHONY: clean
clean:
	rm -rf output*
