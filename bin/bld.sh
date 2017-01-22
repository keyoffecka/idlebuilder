#!/bin/bash

cd $(dirname $0)

ARCH=$(basename $0 | sed -r 's,[^-]+(-.+)?\.sh,\1,')

rm /tmp/bld.log || true
./build$PHASE$ARCH.sh $* | tee /tmp/bld.log
