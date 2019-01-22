
.DEFAULT: all
.PHONY: all
all: centos7

.PHONY: centos7
centos7: output-centos7/centos7/centos7.ovf

output-centos7/centos7/centos7.ovf: centos7.json centos.json kickstart/centos7.cfg scripts/cleanup.sh
	rm -rf output-centos7
	packer build -var-file=centos7.json centos.json


.PHONY: clean
clean:
	rm -rf output*
