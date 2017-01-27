#!/bin/bash

set +h
set -e
set -u

udevadm hwdb --update
