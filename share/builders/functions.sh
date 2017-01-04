#!/bin/bash

function _ask() {
  echo -n "Enter to continue/^C to break"
  
  read
}

function _exec() {
  local file_path="$WORKDIR/share/builders/phase$PHASE/$PKG_FULL_NAME/$1"
  if [ ! -r "$file_path" ] ; then
    file_path="$WORKDIR/share/builders/phase$PHASE/$PKG_LONG_NAME/$1"
  fi
  if [ -r "$file_path" ] ; then
    echo "#Custom $1 script"
    cat $file_path
  fi
}

function _dump_script() {
  if [ -n "$1" ] ; then
    echo "$1"
    echo 
  else
    if [ -n "${2:-}" ] ; then
      echo "Default $2 script"
      echo $3
      echo 
    fi
  fi
}

function _read_props() {
  local file_path="$WORKDIR/share/builders/phase$PHASE/$PKG_FULL_NAME/$1"
  if [ ! -r "$file_path" ] ; then
    file_path="$WORKDIR/share/builders/phase$PHASE/$PKG_LONG_NAME/$1"
  fi
  
  if [ -r "$file_path" ] ; then
    local line=""
    local lines=""
    while read line ; do
      lines="$lines$line "
    done < "$file_path" 
    eval $lines
  fi
}

# Calculated vars:
# ARCH, may be 32 or 64, based on the build script name: build.sh gives 64, build-32.sh goves 32
# PKG_ARCH, may be x86 or x86_64, based on the build script name
# IDLE_TARGET, based on the build script name: build.sh gives the value of $IDLE_TARGET64, build-32.sh gives the value of IDLE_TARGET32
# PKG_NAME, PKG_VERSION, PKG_LONG_NAME, PKG_FULL_NAME, PKG_FILE_NAME are based on source package name.
#
# Phase global vars:
# ROOT, SRC_DIR, DST_DIR, REPO_DIR, IDLE_TARGET32, IDLE_TARGET64, IDLE_HOST - must be set, shouldn't be empty.
# PHASE_NAME, must be set and may be empty, if so, then the binary package will have no pahse name suffix in the full filename.
# LIB_SUFFIX, may be unset or empty, if unset then will be set to $ARCH, if empty will be kept empty.
# 
# init.properties may override calculated and global phase variables and may be calculated based on the global phase variables and other calculated variables.
# 
# PKG_SRC_DIR, PKG_BUILD_DIR, PREFIX, COMPILE_OPTS, COPY_OPTS, CFG, CFG_ENV - may be defined as global phase variables or in init.properties,
# if not set, then default values be used.
#
# post.properties may be used to override any variable and to set its value based on other variable values.
# It is recommended to use post.properties if possible.

function initialize() {
  local script_file_name="$1"
  local src_file_path="$2"

  echo "STEP: initialize"
  
  ARCH=$(echo "$script_file_name" | sed -r 's,build[^-]*(-(.+))?\.sh,\2,')
  ARCH=${ARCH:-"64"}

  PKG_ARCH=x86
  [ "$ARCH" == "64" ] && PKG_ARCH="x86_64" 
  
  if [ "${LIB_SUFFIX-unset}" == "unset" ] ; then
    LIB_SUFFIX=$ARCH
  fi
  
  IDLE_TARGET=$IDLE_TARGET32
  [ "$ARCH" == "64" ] && IDLE_TARGET=$IDLE_TARGET64

  BUILD=$BUILD32
  [ "$ARCH" == "64" ] && BUILD=$BUILD64

  PKG_NAME=$(basename "$src_file_path" | sed -r 's,(.+)-[0-9.]+\.tar\..+,\1,')
  PKG_VERSION=$(basename "$src_file_path" | sed -r 's,.+-([0-9.]+)\.tar\..+,\1,')
  PKG_LONG_NAME=$PKG_NAME-$PKG_VERSION
  PKG_FULL_NAME=$PKG_LONG_NAME-$PKG_ARCH

  local pkg_phase_postfix=
  [ -n "$PHASE_NAME" ] && pkg_phase_postfix=-$PHASE_NAME
  PKG_FILE_NAME=$PKG_FULL_NAME$pkg_phase_postfix.tar.xz
  
  local old_CFG=${CFG:-"_none_"}
  local old_CFG_ENV=${CFG_ENV:-"_none_"}
  local old_COMPILE_OPTS=${COMPILE_OPTS:-"_none_"}
  local old_COPY_OPTS=${COPY_OPTS:-"_none_"}
  local old_PKG_BUILD_DIR=${PKG_BUILD_DIR:-"_none_"}
  local old_PKG_CFG_DIR=${PKG_CFG_DIR:-"_none_"}
  
  _read_props "init.properties"
  
  [ "$old_CFG" != "_none_" ] && CFG="$old_CFG"
  [ "$old_CFG_ENV" != "_none_" ] && CFG_ENV="$old_CFG_ENV"
  [ "$old_COMPILE_OPTS" != "_none_" ] && COMPILE_OPTS="$old_COMPILE_OPTS"
  [ "$old_COPY_OPTS" != "_none_" ] && COPY_OPTS="$old_COPY_OPTS"
  [ "$old_PKG_BUILD_DIR" != "_none_" ] && PKG_BUILD_DIR="$old_PKG_BUILD_DIR"
  [ "$old_PKG_CFG_DIR" != "_none_" ] && PKG_CFG_DIR="$old_PKG_CFG_DIR"
  
  PKG_SRC_DIR=${PKG_SRC_DIR:-$SRC_DIR/$PKG_LONG_NAME}
  PKG_BUILD_DIR=${PKG_BUILD_DIR:-$PKG_SRC_DIR}
  PKG_CFG_DIR=${PKG_CFG_DIR:-$PKG_SRC_DIR}

  PREFIX=${PREFIX:-/usr}

  COMPILE_OPTS=${COMPILE_OPTS:-"-j8"}
  COPY_OPTS=${COPY_OPTS:-"DESTDIR=$DST_DIR/$PKG_LONG_NAME"}
  
  DEFAULT_CFG=${DEFAULT_CFG:-"--prefix=$PREFIX --libdir=$PREFIX/lib$LIB_SUFFIX"}
  CFG=${CFG:-$DEFAULT_CFG}
  
  DEFAULT_CFG_ENV=${DEFAULT_CFG_ENV:-"${DEFAULT_CXXFLAGS:+CXXFLAGS='$DEFAULT_CXXFLAGS'} ${DEFAULT_CFLAGS:+CFLAGS='$DEFAULT_CFLAGS'}"}
  CFG_ENV=${CFG_ENV:-$DEFAULT_CFG_ENV}

  _read_props "post.properties"
  
  DROP_MAN=${DROP_MAN:-"false"}
  DROP_LOCALE=${DROP_LOCALE:-"false"}
 

  [ "$old_CFG" != "_none_" ] && CFG="$old_CFG"
  [ "$old_CFG_ENV" != "_none_" ] && CFG_ENV="$old_CFG_ENV"
  [ "$old_COMPILE_OPTS" != "_none_" ] && COMPILE_OPTS="$old_COMPILE_OPTS"
  [ "$old_COPY_OPTS" != "_none_" ] && COPY_OPTS="$old_COPY_OPTS"
  [ "$old_PKG_BUILD_DIR" != "_none_" ] && PKG_BUILD_DIR="$old_PKG_BUILD_DIR"
  [ "$old_PKG_CFG_DIR" != "_none_" ] && PKG_CFG_DIR="$old_PKG_CFG_DIR"

  fix_script=$(_exec fix)
  config_script=$(_exec config)
  compile_script=$(_exec compile)
  prepare_script=$(_exec prepare)
  copy_script=$(_exec copy)
}

function dump() {
  echo "ARCH                 : $ARCH"
  echo "PKG_ARCH             : $PKG_ARCH"
  echo "PKG_NAME             : $PKG_NAME"
  echo "PKG_VERSION          : $PKG_VERSION"
  echo "PKG_LONG_NAME        : $PKG_LONG_NAME"
  echo "PKG_FULL_NAME        : $PKG_FULL_NAME"
  echo "PKG_FILE_NAME        : $PKG_FILE_NAME"
  echo "PKG_BUILD_DIR        : $PKG_BUILD_DIR"
  echo "PKG_SRC_DIR          : $PKG_SRC_DIR"
  echo "PKG_CFG_DIR          : $PKG_CFG_DIR"
  echo "PREFIX               : $PREFIX"
  echo "LIB_SUFFIX           : $LIB_SUFFIX"
  echo "IDLE_HOST            : $IDLE_HOST"
  echo "IDLE_TARGET          : $IDLE_TARGET"
  echo "COMPILE_OPTS         : $COMPILE_OPTS"
  echo "COPY_OPTS            : $COPY_OPTS"
  echo "CFG                  : $CFG"
  echo "CFG_ENV              : $CFG_ENV"
  echo
  _dump_script "$fix_script"
  _dump_script "$config_script" "config" "$CFG_ENV $PKG_CFG_DIR/configure $CFG"
  _dump_script "$prepare_script"
  _dump_script "$compile_script" "compile" "make $COMPILE_OPTS"
  _dump_script "$copy_script" "copy" "make install $COPY_OPTS"
}

function aide {
  echo "STEP: aide"

  $PKG_SRC_DIR/configure --help
}

function unpack() {
  echo "STEP: unpack"

  rm -fr $PKG_SRC_DIR 2>/dev/null || true
  tar xf $1 -C $(dirname $PKG_SRC_DIR)
}

# Patch file name may inlcude phase name, arch name or non of them:
#   package-version-x86_64-crosstools.pacthes.xz
#   package-version-x86_64.patches.xz
#   package-version.patches.xz
#
# Depending on the name, appropriate patches will be applied depending on the phase and arch.
function fix() {
  echo "STEP: fix"
  
  cd $PKG_SRC_DIR
    
  local patch_file_path=""
  if [ -n "$PHASE_NAME" ] ; then
      patch_file_path="$REPO_DIR/$PKG_LONG_NAME-$PKG_ARCH-$PHASE_NAME.patches.xz"
      [ -r "$patch_file_path" ] || patch_file_path=""
  fi
  if [ -z "$patch_file_path" ] ; then
    patch_file_path="$REPO_DIR/$PKG_LONG_NAME-$PKG_ARCH.patches.xz"
    [ -r "$patch_file_path" ] || patch_file_path=""
  fi
  if [ -z "$patch_file_path" ] ; then
    patch_file_path="$REPO_DIR/$PKG_LONG_NAME.patches.xz"
    [ -r "$patch_file_path" ] || patch_file_path=""
  fi
  if [ -n "$patch_file_path" ] ; then
    unxz -c "$patch_file_path" | patch -Np1
  fi
  
  if [ -n "$fix_script" ] ; then 
    eval "$fix_script" 
  fi
}

function config() {
  echo "STEP: config"

  if [ -d "$PKG_BUILD_DIR" -a -d "$PKG_SRC_DIR" ] ; then
    cd $PKG_BUILD_DIR
    local b=$PWD
    
    cd $PKG_SRC_DIR
    local s=$PWD
    
    if [[ "$s" != "$b"* ]] ; then 
      if [[ "$b" != "$s"* ]] ; then  
        rm -fr $PKG_BUILD_DIR
      fi 
    fi
  fi
  
  mkdir -p $PKG_BUILD_DIR
  cd $PKG_BUILD_DIR
  if [ -n "$config_script" ] ; then 
    eval "$config_script" 
  else
    eval "$CFG_ENV $PKG_CFG_DIR/configure $CFG"
  fi
}

function prepare() {
  echo "STEP: prepare"

  cd $PKG_SRC_DIR
  if [ -n "$prepare_script" ] ; then 
    eval "$prepare_script" 
  fi
}

function compile() {
  echo "STEP: compile"

  cd $PKG_BUILD_DIR
  if [ -n "$compile_script" ] ; then 
    eval "$compile_script" 
  else
    make $COMPILE_OPTS
  fi
}

function copy() {
  echo "STEP: copy"

  rm -fr $DST_DIR/$PKG_LONG_NAME || true
  cd $PKG_BUILD_DIR
  if [ -n "$copy_script" ] ; then 
    eval "$copy_script" 
  else
    make install $COPY_OPTS
  fi
}

function clean() {
  echo "STEP: clean"

  mkdir -p $DST_DIR/$PKG_LONG_NAME/$PREFIX/share
  [ -d "$DST_DIR/$PKG_LONG_NAME/$PREFIX/man" ] && mv $DST_DIR/$PKG_LONG_NAME/$PREFIX/man $DST_DIR/$PKG_LONG_NAME/$PREFIX/share

  rm -fr $DST_DIR/$PKG_LONG_NAME/$PREFIX/{,share}/{info,doc}
  
  [ "$DROP_MAN" == "true" ] && rm -fr $DST_DIR/$PKG_LONG_NAME/$PREFIX/share/man
  [ "$DROP_LOCALE" == "true" ] && rm -fr $DST_DIR/$PKG_LONG_NAME/$PREFIX/share/locale
  
  [ -d "$DST_DIR/$PKG_LONG_NAME/$PREFIX/usr/share/pkgconfig" ] && mv $DST_DIR/$PKG_LONG_NAME/$PREFIX/usr/share/pkgconfig $DST_DIR/$PKG_LONG_NAME/$PREFIX/usr/lib$LIB_SUFFIX

  if [ -d "$DST_DIR/$PKG_LONG_NAME/$PREFIX/share" ] ; then
    [ -z "$(command ls -1 $DST_DIR/$PKG_LONG_NAME/$PREFIX/share)" ] && rm -fr $DST_DIR/$PKG_LONG_NAME/$PREFIX/share
  fi
  
  if [ -d $DST_DIR/$PKG_LONG_NAME/lib ] ; then
    mkdir -p $DST_DIR/$PKG_LONG_NAME/$PREFIX/lib$LIB_SUFFIX
    mv $DST_DIR/$PKG_LONG_NAME/lib/* $DST_DIR/$PKG_LONG_NAME/$PREFIX/lib$LIB_SUFFIX
    rm -fr $DST_DIR/$PKG_LONG_NAME/lib
  fi
  if [ -d $DST_DIR/$PKG_LONG_NAME/$PREFIX/lib ] ; then
    mkdir -p $DST_DIR/$PKG_LONG_NAME/$PREFIX/lib$LIB_SUFFIX
    mv $DST_DIR/$PKG_LONG_NAME/$PREFIX/lib/* $DST_DIR/$PKG_LONG_NAME/$PREFIX/lib$LIB_SUFFIX
    rm -fr $DST_DIR/$PKG_LONG_NAME/$PREFIX/lib
  fi
  if [ -d $DST_DIR/$PKG_LONG_NAME/lib32 ] ; then
    mkdir -p $DST_DIR/$PKG_LONG_NAME/$PREFIX/lib32
    mv $DST_DIR/$PKG_LONG_NAME/lib32/* $DST_DIR/$PKG_LONG_NAME/$PREFIX/lib32
    rm -fr $DST_DIR/$PKG_LONG_NAME/lib32
  fi
  if [ -d $DST_DIR/$PKG_LONG_NAME/lib64 ] ; then
    mkdir -p $DST_DIR/$PKG_LONG_NAME/$PREFIX/lib64
    mv $DST_DIR/$PKG_LONG_NAME/lib64/* $DST_DIR/$PKG_LONG_NAME/$PREFIX/lib64
    rm -fr $DST_DIR/$PKG_LONG_NAME/lib64
  fi
  if [ -d $DST_DIR/$PKG_LONG_NAME/$PREFIX/sbin ] ; then
    mkdir -p $DST_DIR/$PKG_LONG_NAME/$PREFIX/bin
    mv $DST_DIR/$PKG_LONG_NAME/$PREFIX/sbin/* $DST_DIR/$PKG_LONG_NAME/$PREFIX/bin
    rm -fr $DST_DIR/$PKG_LONG_NAME/$PREFIX/sbin
  fi
  if [ -d $DST_DIR/$PKG_LONG_NAME/sbin ] ; then
    mkdir -p $DST_DIR/$PKG_LONG_NAME/$PREFIX/bin
    mv $DST_DIR/$PKG_LONG_NAME/sbin/* $DST_DIR/$PKG_LONG_NAME/$PREFIX/bin
    rm -fr $DST_DIR/$PKG_LONG_NAME/sbin
  fi
  
  find $DST_DIR/$PKG_LONG_NAME/$PREFIX/{,usr/}{bin,sbin,lib,lib32,lib64} -type f -exec strip --strip-debug '{}' ';' 2>/dev/null || true
}

function package() {
  echo "STEP: package"

  [ -r "$DST_DIR/$PKG_FILE_NAME" ] && rm $DST_DIR/$PKG_FILE_NAME
  cd $DST_DIR/$PKG_LONG_NAME
  tar cJf $DST_DIR/$PKG_FILE_NAME *
}

function deploy() {
  echo "STEP: deploy"

  tar xf $DST_DIR/$PKG_FILE_NAME -C $ROOT
}