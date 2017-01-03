#!/bin/bash

set +h
set -e
set -u

cd $(dirname $0)/..

if [ ! -d "$IDLE_ROOT" ] ; then
  echo "$IDLE_ROOT is not a directory"
  exit -1
fi

mkdir -pv $IDLE_ROOT/$TOOLS_DIR
mkdir -pv $IDLE_ROOT/{boot,dev,etc,opt,home,mnt,proc,sys}
mkdir -pv $IDLE_ROOT/usr/{local/,}{bin,include,lib{32,64},src}
mkdir -pv $IDLE_ROOT/usr/{local/,}share/{doc,info,locale,man}
mkdir -pv $IDLE_ROOT/usr/{local/,}share/man/man{1..8}
mkdir -pv $IDLE_ROOT/usr/share/{misc,terminfo,zoneinfo}
mkdir -pv $IDLE_ROOT/var/{lock,log,mail,spool,lib,srv}
mkdir -pv $IDLE_ROOT/var/cache/idle/{repo,dst}

install -dv $IDLE_ROOT/root -m 0750
install -dv $IDLE_ROOT/tmp -m 1777
install -dv $IDLE_ROOT/var/run -m 1777

ln -sv var/run $IDLE_ROOT/run
ln -sv var/srv $IDLE_ROOT/srv
ln -sv lib64 $IDLE_ROOT/usr/lib
ln -sv bin $IDLE_ROOT/usr/sbin
ln -sv usr/bin $IDLE_ROOT/bin
ln -sv usr/sbin $IDLE_ROOT/sbin
ln -sv usr/lib $IDLE_ROOT/lib
ln -sv usr/lib32 $IDLE_ROOT/lib32
ln -sv usr/lib64 $IDLE_ROOT/lib64
ln -sv bin $IDLE_ROOT/usr/local/sbin
ln -sv lib64 $IDLE_ROOT/usr/local/lib
ln -sv ../run/shm $IDLE_ROOT/dev/shm

ln -sv lib64 $IDLE_ROOT/$TOOLS_DIR/lib

mknod -m 600 ${ROOT}/dev/console c 5 1
mknod -m 666 ${ROOT}/dev/null c 1 3

install -v -m 0640 -o 0 -g 0 share/files/passwd $IDLE_ROOT/etc
install -v -m 0640 -o 0 -g 0 share/files/group $IDLE_ROOT/etc

touch $IDLE_ROOT/var/log/{btmp,faillog,lastlog,wtmp}
chgrp -v 13 $IDLE_ROOT/var/log/{faillog,lastlog}
chmod -v 664 $IDLE_ROOT/var/log/{faillog,lastlog}
chmod -v 600 $IDLE_ROOT/var/log/btmp
