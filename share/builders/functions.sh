#!/bin/bash

function _ask() {
  echo -n "Enter to continue/^C to break"
  
  read
}

function _exec() {
  local file_path="$WORKDIR/share/builders/phase$PHASE/$PKG_LONG_NAME/$1"
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
  local file_path="$WORKDIR/share/builders/phase$PHASE/$PKG_LONG_NAME/$1"
  if [ -r "$file_path" ] ; then
    local line=""
    local lines=""
    while read line ; do
      lines="$lines$line "
    done < "$file_path" 
    eval $lines
  fi
}

function initialize() {
  local script_file_name="$1"
  local src_file_path="$2"

  echo "STEP: initialize"
  
  ARCH=$(echo "$script_file_name" | sed -r 's,build[^-]*(-(.+))?\.sh,\2,')
  ARCH=${ARCH:-"64"}

  PKG_ARCH=x86
  [ "$ARCH" == "64" ] && PKG_ARCH="x86_64" 
  
  IDLE_TARGET=$IDLE_TARGET32
  [ "$ARCH" == "64" ] && IDLE_TARGET=$IDLE_TARGET64
  
  PKG_NAME=$(basename "$src_file_path" | sed -r 's,(.+)-[0-9.]+\.tar\..+,\1,')
  PKG_VERSION=$(basename "$src_file_path" | sed -r 's,.+-([0-9.]+)\.tar\..+,\1,')
  PKG_LONG_NAME=$PKG_NAME-$PKG_VERSION
  PKG_FULL_NAME=$PKG_LONG_NAME-$PKG_ARCH

  local pkg_phase_postfix=
  [ -n "$PHASE_NAME" ] && pkg_phase_postfix=-$PHASE_NAME
  
  PKG_FILE_NAME=$PKG_FULL_NAME$pkg_phase_postfix.tar.xz
  
  _read_props "init.properties"

  PKG_SRC_DIR=${PKG_SRC_DIR:-$SRC_DIR/$PKG_LONG_NAME}
  PKG_BUILD_DIR=${PKG_BUILD_DIR:-$PKG_SRC_DIR}
  
  PREFIX=${PREFIX:-/usr}

  LIB_SUFFIX=$ARCH
  
  COMPILE_OPTS=${COMPILE_OPTS:-"-j8"}
  COPY_OPTS=${COPY_OPTS:-"DESTDIR=$DST_DIR/$PKG_LONG_NAME"}
  
  CFG=${CFG:-"--prefix=$PREFIX --libdir=$PREFIX/lib$LIB_SUFFIX"}
  CFG_ENV=${CFG_ENV:-}

  _read_props "post.properties"

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
  echo "PREFIX               : $PREFIX"
  echo "LIB_SUFFIX           : $LIB_SUFFIX"
  echo "IDLE_TARGET          : $IDLE_TARGET"
  echo
  _dump_script "$fix_script"
  _dump_script "$config_script" "config" "$CFG_ENV $SRC_DIR/$PKG_LONG_NAME/configure $CFG"
  _dump_script "$compile_script" "compile" "make $COMPILE_OPTS"
  _dump_script "$prepare_script" "copy" "make install $COPY_OPTS"
  _dump_script "$copy_script"
}

function unpack() {
  echo "STEP: unpack"

  rm -fr $SRC_DIR/$PKG_LONG_NAME 2>/dev/null || true
  tar xf $1 -C $SRC_DIR
}

function fix() {
  echo "STEP: fix"
  
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
    cd $SRC_DIR/$PKG_LONG_NAME
    
    xz -c "$patch_file_path" | patch -Np1
  fi

  if [ -n "$fix_script" ] ; then 
    eval "$fix_script" 
  fi
}

function config() {
  echo "STEP: config"

  if [ -n "$config_script" ] ; then 
    eval "$config_script" 
  else
    mkdir -p $PKG_BUILD_DIR
    cd $PKG_BUILD_DIR
    eval "$CFG_ENV $SRC_DIR/$PKG_LONG_NAME/configure $CFG"
  fi
}

function prepare() {
  echo "STEP: prepare"

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
  if [ -n "$copy_script" ] ; then 
    eval "$copy_script" 
  else
    make install $COPY_OPTS
  fi
}

function clean() {
  echo "STEP: clean"

  [ -d "$DST_DIR/$PKG_LONG_NAME/$PREFIX/man" ] && mv $DST_DIR/$PKG_LONG_NAME/$PREFIX/man $DST_DIR/$PKG_LONG_NAME/$PREFIX/share

  rm -fr $DST_DIR/$PKG_LONG_NAME/$PREFIX/{,share}/{info,doc}
  
  [ "$DROP_MAN" == "true" ] && rm -fr $DST_DIR/$PKG_LONG_NAME/$PREFIX/share/man
  
  [ -d "$DST_DIR/$PKG_LONG_NAME/$PREFIX/usr/share/pkgconfig" ] && mv $DST_DIR/$PKG_LONG_NAME/$PREFIX/usr/share/pkgconfig $DST_DIR/$PKG_LONG_NAME/$PREFIX/usr/lib$LIB_SUFFIX

  if [ -d "$DST_DIR/$PKG_LONG_NAME/$PREFIX/share" ] ; then
    [ -z "$(command ls -1 $DST_DIR/$PKG_LONG_NAME/$PREFIX/share)" ] && rm -fr $DST_DIR/$PKG_LONG_NAME/$PREFIX/share
  fi
  
  find $DST_DIR/$PKG_LONG_NAME/$PREFIX/{,usr/}{bin,sbin,lib32,lib64} -type f -exec strip --strip-debug '{}' ';' 2>/dev/null || true
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