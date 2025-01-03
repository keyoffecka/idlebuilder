#!/bin/bash

#Should be executed manually once before starting the phase 0

set -eu +h

WORK_DIR=

cd "$(dirname $0)"/../share/builders/phase"$PHASE"/"$(basename "$0" .sh)"
WORK_DIR="$PWD"

cd ../../../..
IDLEBUILDER_HOME="$PWD"

cd "$WORK_DIR"

if [[ -x "$IDLE_ROOT/$TOOLS_DIR" && ! -d "$IDLE_ROOT/$TOOLS_DIR" ]] ; then
  echo "$IDLE_ROOT/$TOOLS_DIR is not a directory"
  exit -1
fi

source init.properties

mkdir -pv "$IDLE_ROOT/$TOOLS_DIR"
mkdir -pv "$IDLE_ROOT"/{boot,dev,etc,lib,opt,home,mnt,proc,sys}
mkdir -pv "$IDLE_ROOT"/usr/{local/,}{bin,include,lib,src}
mkdir -pv "$IDLE_ROOT"/usr/{local/,}share/{doc,info,locale,man}
mkdir -pv "$IDLE_ROOT"/usr/{local/,}share/man/man{1..8}
mkdir -pv "$IDLE_ROOT"/usr/share/{misc,terminfo,zoneinfo}
mkdir -pv "$IDLE_ROOT"/var/{lock,log,mail,spool,lib,srv}
mkdir -pv "$IDLE_ROOT"/var/cache/idle/{repo,dst}

install -dv "$IDLE_ROOT"/home/root -m 0750
install -dv "$IDLE_ROOT"/tmp -m 1777
install -dv "$IDLE_ROOT"/var/run -m 1777

ln -svf usr/bin "$IDLE_ROOT"/bin
ln -svf var/run "$IDLE_ROOT"/run
ln -svf var/srv "$IDLE_ROOT"/srv
ln -svf bin "$IDLE_ROOT"/sbin
ln -svf bin "$IDLE_ROOT"/usr/sbin
ln -svf bin "$IDLE_ROOT"/usr/local/sbin
ln -svf ../run/shm "$IDLE_ROOT"/dev/shm

[[ -c "${IDLE_ROOT}"/dev/console ]] || mknod -m 600 "${IDLE_ROOT}"/dev/console c 5 1
[[ -c "${IDLE_ROOT}"/dev/null ]] || mknod -m 666 "${IDLE_ROOT}"/dev/null c 1 3

install -v -m 0640 -o 0 -g 0 "$IDLEBUILDER_HOME"/share/files/fstab "$IDLE_ROOT"/etc
install -v -m 0640 -o 0 -g 0 "$IDLEBUILDER_HOME"/share/files/passwd "$IDLE_ROOT"/etc
install -v -m 0640 -o 0 -g 0 "$IDLEBUILDER_HOME"/share/files/group "$IDLE_ROOT"/etc

sed -r \
  -e "s/RRRR/$ROOT_DEV/g" \
  -e "s/TTTT/$ROOT_FS_TYPE/g" \
  -e "s/SSSS/$SWAP_DEV/g" \
  -i "$IDLE_ROOT"/etc/fstab

touch "$IDLE_ROOT"/var/log/{btmp,faillog,lastlog,wtmp}
chgrp -v 13 "$IDLE_ROOT"/var/log/{faillog,lastlog}
chmod -v 664 "$IDLE_ROOT"/var/log/{faillog,lastlog}
chmod -v 600 "$IDLE_ROOT"/var/log/btmp
