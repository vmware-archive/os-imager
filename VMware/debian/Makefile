
.DEFAULT: all
.PHONY: all
all: debian8 debian9

.PHONY: debian8
debian8: output-debian8/debian8/debian8.ovf

output-debian8/debian8/debian8.ovf: debian8.json debian.json http/preseed.cfg scripts/cleanup.sh
	rm -rf output-debian8
	packer build -var-file=debian8.json debian.json

.PHONY: debian9
debian9: output-debian9/debian9/debian9.ovf

output-debian9/debian9/debian9.ovf: debian9.json debian.json http/preseed.cfg scripts/cleanup.sh
	rm -rf output-debian9
	sleep 5
	packer build -var-file=debian9.json debian.json

.PHONY: clean
clean:
	rm -rf output*
