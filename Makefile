# Minimal makefile for running packer lint

OS  = 
OS_REV  = 
PACKERDIR  = AWS
REGION  = us-west-2

.PHONY: help
help:
	@echo ''
	@echo '  Targets:'
	@echo '    build'
	@echo ''
	@echo '  Usage:'
	@echo '    make validate OS=<SOME OS> OS_REV=<SOME OS REVISION>'

.PHONY: validate
validate: 
	@packer validate -var-file=$(PACKERDIR)/$(OS)/$(OS)-$(OS_REV)-$(REGION).json $(PACKERDIR)/$(OS)/$(OS).json
