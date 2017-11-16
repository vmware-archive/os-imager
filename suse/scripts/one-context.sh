#!/bin/bash

# setup one context
rpm -q --scripts one-context | sed -n '/postinstall/,/preuninstall/{//!p}' | bash -s -- 1
