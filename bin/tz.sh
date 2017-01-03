#!/bin/bash

#Should be executed mannually once after installing GLibC x86_64 for the base system.

set +h
set -e
set -u

if [ "$#" != 1 ] ; then
  echo "Wrong number of arguments"
  exit -1
fi

TZ="$1"

PKG_LONG_NAME=tzdata2016f
ZONEINFO_DIR=$DST_DIR/$PKG_LONG_NAME/usr/share/zoneinfo

rm -fr $DST_DIR/$PKG_LONG_NAME || true
mkdir -pv $ZONEINFO_DIR/{posix,right}

rm -fr $SRC_DIR/$PKG_LONG_NAME || true
mkdir -p $SRC_DIR/$PKG_LONG_NAME
tar -xf $REPO_DIR/$PKG_LONG_NAME.tar.gz -C $SRC_DIR/$PKG_LONG_NAME

cd $SRC_DIR/$PKG_LONG_NAME

for tz in etcetera southamerica northamerica europe africa antarctica asia australasia backward pacificnew systemv; do
  /usr/bin/zic -L /dev/null   -d $ZONEINFO_DIR       -y "sh yearistype.sh" ${tz}
  /usr/bin/zic -L /dev/null   -d $ZONEINFO_DIR/posix -y "sh yearistype.sh" ${tz}
  /usr/bin/zic -L leapseconds -d $ZONEINFO_DIR/right -y "sh yearistype.sh" ${tz}
done
                      
cp -v zone.tab zone1970.tab iso3166.tab $ZONEINFO_DIR
/usr/bin/zic -d $ZONEINFO_DIR -p America/New_York

if [ ! -r "$ZONEINFO_DIR/$TZ" ] ; then
  echo "$ZONEINFO_DIR/$TZ is not readable"
  exit -2
fi

mkdir -p $DST_DIR/$PKG_LONG_NAME/etc
ln -sv /usr/share/zoneinfo/$TZ $DST_DIR/$PKG_LONG_NAME/etc/localtime

cd $DST_DIR/$PKG_LONG_NAME
/tools/bin/tar -c -O * | /tools/bin/xz -9 > $DST_DIR/$PKG_LONG_NAME.tar.xz
