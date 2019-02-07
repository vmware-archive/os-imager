# Minimal makefile for running packer lint

OS  =
OS_REV  =
PACKERDIR  = AWS
REGION  = us-west-2
TEMPLATE = $(PACKERDIR)/$(OS)/$(OS).json
VAR_FILE = $(PACKERDIR)/$(OS)/$(OS)-$(OS_REV)-$(REGION).json

.PHONY: help
help:
	@echo ''
	@echo '  Targets:'
	@echo '    build, validate'
	@echo ''
	@echo '  Usage:'
	@echo '    make <target> OS=<SOME OS> OS_REV=<SOME OS REVISION>'

.PHONY: validate
validate:
	$(info OS=$(OS))
	$(info OS_REV=$(OS_REV))
	$(info TEMPLATE=$(TEMPLATE))
	$(info VAR_FILE=$(VAR_FILE))
	@packer validate -var-file=$(VAR_FILE) $(TEMPLATE)

.PHONY: build
build:
	$(info OS=$(OS))
	$(info OS_REV=$(OS_REV))
	$(info TEMPLATE=$(TEMPLATE))
	$(info VAR_FILE=$(VAR_FILE))
	@packer build -var-file=$(VAR_FILE) $(TEMPLATE)
