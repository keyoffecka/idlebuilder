#!/bin/bash

set +h
set -e
set -u

source $WORKDIR/share/builders/functions.sh

initialize "$(basename $0)" "$1"
dump
_ask
unpack "$1"
fix
config
prepare
compile
copy
clean
_ask
package
deploy

