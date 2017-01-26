#!/bin/bash

set +h
set -e
set -u

cd $(dirname $0)

export ARCH=$(basename $0 | sed -r 's,[^-]+(-(.+))?\.sh,\2,')
[ -z "$ARCH" ] && export ARCH="64"

export IDLE_CONFIG=$(basename $0 | sed -r 's,([^-]+)(-.+)?\.sh,\1,')

function run() {
  rm /tmp/bld.result >/dev/null 2>&1 || true
  if ! ./build.sh $* ; then
    echo $? > /tmp/bld.result
  fi
}

rm /tmp/bld.log >/dev/null 2>&1 || true
run $* 2>&1 | tee /tmp/bld.log
if [ -r /tmp/bld.result ] ; then
  exit -1
fi
