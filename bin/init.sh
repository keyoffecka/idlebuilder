#!/bin/bash

set +h
set -e
set -u

cd $(dirname $0)/..

WORKDIR=$PWD

PHASE=$(basename $0 | sed -r 's,init(.+)\.sh,\1,')
IDLE_VERSION=$(basename $WORKDIR | sed -r 's,idlebuilder-(.+),\1,')

bash -c "sudo env -i HOME=$HOME USER=$USER TERM=$TERM PS1='\u:\w [phase$PHASE]: ' IDLE_VERSION=$IDLE_VERSION WORKDIR=$WORKDIR PHASE=$PHASE bash --rcfile etc/phase$PHASE/bash.rc"

