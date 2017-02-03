#!/bin/bash

set +h
set -e
set -u

cd "$(dirname $0)"

name=$1
file="$WORKDIR/share/files/$name.md5"

case "$name" in
  proto)
    base="http://ftp.x.org/pub/individual/proto/"
    ;;
  lib)
    base="http://ftp.x.org/pub/individual/lib/"
    ;;
  app)
    base="http://ftp.x.org/pub/individual/app/"
    ;;
  font)
    base="http://ftp.x.org/pub/individual/font/"
    ;;
esac

mkdir -pv "$REPO_DIR/$name"
    
grep -v '^#' "$file" | awk '{print $2}' | wget -i- -c --no-check-certificate -P "$REPO_DIR/$name" -B "$base"
grep -v '^#' "$file" | sed -r "s,(.+)\s+(.+),\1$REPO_DIR/$name/\2," | md5sum -c -
