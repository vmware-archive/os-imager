# Minimal makefile for running packer lint

OS  = 
OS_REV  = 
PACKERDIR  = AWS
REGION  = us-west-2

.PHONY: help Makefile
%: Makefile
build:
	packer validate -var-file=$(PACKERDIR)/$(OS)/$(OS)-$(OS_REV)-$(REGION).json $(PACKERDIR)/$(OS)/$(OS).json
