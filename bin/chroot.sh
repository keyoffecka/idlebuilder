#!/bin/bash

set +h
set -e
set -u

export HOME=/root
export WORKDIR=${WORKDIR#$IDLE_ROOT}

function isMount() {
  local retval=1
  mount | grep -q " $1 " && retval=0
  return $retval
}

isMount ${IDLE_ROOT}/dev || mount -o bind /dev ${IDLE_ROOT}/dev
isMount ${IDLE_ROOT}/dev/pts || mount -t devpts -o gid=5,mode=620 devpts ${IDLE_ROOT}/dev/pts
isMount ${IDLE_ROOT}/proc || mount -t proc proc ${IDLE_ROOT}/proc
isMount ${IDLE_ROOT}/sys || mount -t sysfs sysfs ${IDLE_ROOT}/sys
isMount ${IDLE_ROOT}/var/run || mount -t tmpfs tmpfs ${IDLE_ROOT}/var/run

isMount ${IDLE_ROOT}/var/cache/idle || mount --bind /storage/cache-idle-1.0.1/idle ${IDLE_ROOT}/var/cache/idle
isMount ${IDLE_ROOT}/usr/src || mount --bind /storage/cache-idle-1.0.1/src ${IDLE_ROOT}/usr/src

install -d -o 0 -g 0 -m 1777 ${IDLE_ROOT}/var/run/shm

$TOOLS_DIR/bin/chroot $IDLE_ROOT $ROOT/bin/bash --rcfile $WORKDIR/etc/phase$PHASE/chroot-bash.rc || true

umount $IDLE_ROOT/usr/src
umount $IDLE_ROOT/var/cache/idle

umount $IDLE_ROOT/dev/pts
umount $IDLE_ROOT/dev
umount $IDLE_ROOT/var/run
umount $IDLE_ROOT/sys
umount $IDLE_ROOT/proc

