#!/bin/bash

set +h
set -e
set -u

cd $(dirname $0)/..

if [ ! -d "$ROOT" ] ; then
  echo "$ROOT is not a directory"
  exit -1
fi

mkdir -pv $ROOT/$TOOLS_DIR
mkdir -pv $ROOT/{boot,dev,etc,opt,home,mnt,proc,sys}
mkdir -pv $ROOT/usr/{local/,}{bin,include,lib{32,64},src}
mkdir -pv $ROOT/usr/{local/,}share/{doc,info,locale,man}
mkdir -pv $ROOT/usr/{local/,}share/man/man{1..8}
mkdir -pv $ROOT/usr/share/{misc,terminfo,zoneinfo}
mkdir -pv $ROOT/var/{lock,log,mail,spool,lib,srv}
mkdir -pv $ROOT/var/cache/idle/{repo,dst}

install -dv $ROOT/root -m 0750
install -dv $ROOT/tmp -m 1777
install -dv $ROOT/var/run -m 1777

ln -sv var/run $ROOT/run
ln -sv var/srv $ROOT/srv
ln -sv lib64 $ROOT/usr/lib
ln -sv bin $ROOT/usr/sbin
ln -sv usr/bin $ROOT/bin
ln -sv usr/sbin $ROOT/sbin
ln -sv usr/lib $ROOT/lib
ln -sv usr/lib32 $ROOT/lib32
ln -sv usr/lib64 $ROOT/lib64
ln -sv bin $ROOT/usr/local/sbin
ln -sv lib64 $ROOT/usr/local/lib
ln -sv ../run/shm $ROOT/dev/shm

mknod -m 600 ${ROOT}/dev/console c 5 1
mknod -m 666 ${ROOT}/dev/null c 1 3

install -v -m 0640 -o 0 -g 0 share/files/passwd $ROOT/etc
install -v -m 0640 -o 0 -g 0 share/files/group $ROOT/etc

touch $ROOT/var/log/{btmp,faillog,lastlog,wtmp}
chgrp -v 13 $ROOT/var/log/{faillog,lastlog}
chmod -v 664 $ROOT/var/log/{faillog,lastlog}
chmod -v 600 $ROOT/var/log/btmp
