#!/bin/bash

cd $(dirname $0)

ARCH=$(basename $0 | sed -r 's,[^-]+(-.+)?\.sh,\1,')

./build$PHASE$ARCH.sh $*
