#!/bin/bash

set +h
set -e
set -u

cd $(dirname $0)

name="$1"
file="$WORKDIR/share/files/$name.md5"
ARCH=`basename $0 | sed -r 's,[^-]+(-.+)?\.sh,\1,'`

export BUILD_SKIP=y
export DST_DIR="$DST_DIR/$name"

mkdir -pv "$DST_DIR"

for package in $(grep -v '^#' "$file" | awk '{print $2}') ; do
  $WORKDIR/bin/bld$ARCH.sh "$REPO_DIR/$name/$package"
  echo "DONE: $REPO_DIR/$name/$package"
done
