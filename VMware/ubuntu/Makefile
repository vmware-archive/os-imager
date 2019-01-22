
.DEFAULT: all
.PHONY: all
all: ubuntu1604 ubuntu1804

.PHONY: ubuntu1604
ubuntu1604: output-ubuntu1604/ubuntu1604/ubuntu1604.ovf

output-ubuntu1604/ubuntu1604/ubuntu1604.ovf: ubuntu1604.json ubuntu.json http/preseed.cfg scripts/cleanup.sh
	rm -rf output-ubuntu1604
	packer build -var-file=ubuntu1604.json ubuntu.json

.PHONY: ubuntu1804
ubuntu1804: output-ubuntu1804/ubuntu1804/ubuntu1804.ovf

output-ubuntu1804/ubuntu1804/ubuntu1804.ovf: ubuntu1804.json ubuntu.json http/preseed.cfg scripts/cleanup.sh
	rm -rf output-ubuntu1804
	sleep 5
	packer build -var-file=ubuntu1804.json ubuntu.json

.PHONY: clean
clean:
	rm -rf output*
