#!/bin/bash

set +h
set -e
set -u

cd $(dirname $0)/..

WORKDIR=$PWD

PHASE=$(basename $0 | sed -r 's,init(.+)\.sh,\1,')
IDLE_VERSION=$(basename $WORKDIR | sed -r 's,idlebuilder-(.+),\1,')

SUDO="sudo "
[ "$(id --user)" == "0" ] && SUDO= 

bash -c "${SUDO}env -i PATH="/bin:/sbin:/usr/bin:/usr/sbin" HOME=$HOME USER=$USER TERM=$TERM IDLE_VERSION=$IDLE_VERSION WORKDIR=$WORKDIR PHASE=$PHASE bash --rcfile etc/phase$PHASE/bash.rc"

