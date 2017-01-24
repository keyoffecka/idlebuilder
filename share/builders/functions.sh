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
  fi
}

function _read_file_props {
  local file_path="$1"

  if [ -r "$file_path" ] ; then
    local line=""
    local lines=""
    while read line ; do
      lines="$lines$line "
    done < "$file_path" 
    eval $lines
  fi
}

function _read_props() {
  local file_path="$WORKDIR/share/builders/phase$PHASE/$PKG_FULL_NAME/$1"
  if [ ! -r "$file_path" ] ; then
    file_path="$WORKDIR/share/builders/phase$PHASE/$PKG_LONG_NAME/$1"
  fi

  _read_file_props $file_path
}

function _clean_build_dir_and_cd() {
  echo "$PKG_BUILD_DIR $PKG_SRC_DIR"
  if [ -d "$PKG_BUILD_DIR" -a -d "$PKG_SRC_DIR" ] ; then
    cd $PKG_BUILD_DIR
    local b=$PWD
    
    cd $PKG_SRC_DIR
    local s=$PWD
    
    if [[ "$s" != "$b"* ]] ; then
      if [[ "$b" != "$s"* ]] ; then  
        rm -frv $PKG_BUILD_DIR
      fi
    fi
  fi
  
  mkdir -p $PKG_BUILD_DIR
  cd $PKG_BUILD_DIR
}

function initialize() {
  local src_file_path="$1"

  echo "STEP: initialize"
  
  PKG_ARCH=x86
  [ "$ARCH" == "64" ] && PKG_ARCH="x86_64" 
  
  if [ "${LIB_SUFFIX-unset}" == "unset" ] ; then
    LIB_SUFFIX=$ARCH
  fi
  
  IDLE_TARGET=$IDLE_TARGET32
  [ "$ARCH" == "64" ] && IDLE_TARGET=$IDLE_TARGET64

  BUILD=$BUILD32
  [ "$ARCH" == "64" ] && BUILD=$BUILD64

  PKG_NAME=$(basename "$src_file_path" | sed -r 's,(.+)-[0-9].*\.tar\..+,\1,')
  PKG_VERSION=$(basename "$src_file_path" | sed -r 's,.+-([0-9].*)\.tar\..+,\1,')
  PKG_LONG_NAME=$PKG_NAME-$PKG_VERSION
  PKG_FULL_NAME=$PKG_LONG_NAME-$PKG_ARCH

  local pkg_phase_postfix=
  [ -n "$PHASE_NAME" ] && pkg_phase_postfix=-$PHASE_NAME
  PKG_FILE_NAME=$PKG_FULL_NAME$pkg_phase_postfix.tar.xz
  
  PREFIX=${PREFIX:-/usr}

  DROP_MAN=${DROP_MAN:-"false"}
  DROP_LOCALE=${DROP_LOCALE:-"false"}
  
  local old_CMAKE_CFG=${CMAKE_CFG:-"_none_"}
  local old_CFG=${CFG:-"_none_"}
  local old_CFG_ENV=${CFG_ENV:-"_none_"}
  local old_COMPILE_OPTS=${COMPILE_OPTS:-"_none_"}
  local old_COPY_OPTS=${COPY_OPTS:-"_none_"}
  local old_PATCH_OPTS=${PATCH_OPTS:-"_none_"}
  
  _read_file_props "$WORKDIR/etc/phase$PHASE/phase$PHASE.properties"

  COMPILE_OPTS=${COMPILE_OPTS:-"-j8"}
  COPY_OPTS=${COPY_OPTS:-"DESTDIR=$DST_DIR/$PKG_LONG_NAME"}
  PATCH_OPTS=${PATCH_OPTS:-"-Np1"}

  #PKG_SRC_DIR       ->PKG_BUILD_DIR,PKG_CFG_DIR
  #LIB_SUFFIX        ->DEFAULT_CFG,CFG
  #PREFIX            ->DEFAULT_CFG,CFG
  #DEFAULT_CMAKE_CFG ->CMAKE_CFG
  #DEFAULT_CFG       ->CFG
  #DEFAULT_CFG_ENV   ->CFG_ENV
  #DEFAULT_CXXFLAGS  ->DEFAULT_CFG_ENV,CFG_ENV,DEFAULT_CMAKE_CFG,CMAKE_CFG
  #DEFAULT_CFLAGS    ->DEFAULT_CFG_ENV,CFG_ENV,DEFAULT_CMAKE_CFG,CMAKE_CFG
  #PKG_CONFIG_PATH_64->PKG_CONFIG_PATH
  #PKG_CONFIG_PATH_32->PKG_CONFIG_PATH
  #CC_32             ->CC
  #CC_64             ->CC
  #CXX_32            ->CXX
  #CXX_64            ->CXX
  
  _read_props "init.properties"

  [ "$old_CMAKE_CFG" != "_none_" ] && CMAKE_CFG="$old_CMAKE_CFG"
  [ "$old_CFG" != "_none_" ] && CFG="$old_CFG"
  [ "$old_CFG_ENV" != "_none_" ] && CFG_ENV="$old_CFG_ENV"
  [ "$old_COMPILE_OPTS" != "_none_" ] && COMPILE_OPTS="$old_COMPILE_OPTS"
  [ "$old_COPY_OPTS" != "_none_" ] && COPY_OPTS="$old_COPY_OPTS"
  [ "$old_PATCH_OPTS" != "_none_" ] && PATCH_OPTS="$old_PATCH_OPTS"
  
  PKG_SRC_DIR=${PKG_SRC_DIR:-$SRC_DIR/$PKG_LONG_NAME}
  if [ "$IDLE_CONFIG" == "mk" ] ; then
    PKG_BUILD_DIR=${PKG_BUILD_DIR:-$PKG_SRC_DIR/build}
  else
    PKG_BUILD_DIR=${PKG_BUILD_DIR:-$PKG_SRC_DIR}
  fi
  PKG_CFG_DIR=${PKG_CFG_DIR:-$PKG_SRC_DIR}

  if [ -z "${DEFAULT_CMAKE_CFG:-}" ] ; then
    DEFAULT_CMAKE_CFG="-DCMAKE_INSTALL_PREFIX=$PREFIX -DCMAKE_C_FLAGS='$BUILD ${DEFAULT_CFLAGS:-}' -DCMAKE_CXX_FLAGS='$BUILD ${DEFAULT_CXXFLAGS:-}'"
  fi
  CMAKE_CFG=${CMAKE_CFG:-$DEFAULT_CMAKE_CFG}
  
  DEFAULT_CFG=${DEFAULT_CFG:-"--prefix=$PREFIX --libdir=$PREFIX/lib$LIB_SUFFIX"}
  CFG=${CFG:-$DEFAULT_CFG}
  
  DEFAULT_CFG_ENV=${DEFAULT_CFG_ENV:-"${DEFAULT_CXXFLAGS:+CXXFLAGS='$DEFAULT_CXXFLAGS'} ${DEFAULT_CFLAGS:+CFLAGS='$DEFAULT_CFLAGS'}"}
  CFG_ENV=${CFG_ENV:-$DEFAULT_CFG_ENV}
  
  if [ -z "${PKG_CONFIG_PATH:-}" ] ; then
    if [ "$ARCH" == "64" -a -n "${PKG_CONFIG_PATH_64:-}" ] ; then
      export PKG_CONFIG_PATH=$PKG_CONFIG_PATH_64
    elif [ -n "${PKG_CONFIG_PATH_32:-}" ] ; then
      export PKG_CONFIG_PATH=$PKG_CONFIG_PATH_32
    fi
  fi

  if [ -z "${CC:-}" ] ; then
    if [ "$ARCH" == "64" -a -n "${CC_64:-}" ] ; then
      export CC=$CC_64
    elif [ -n "${CC_32:-}" ] ; then
      export CC=$CC_32
    fi
  fi

  if [ -z "${CXX:-}" ] ; then
    if [ "$ARCH" == "64" -a -n "${CXX_64:-}" ] ; then
      export CXX=$CXX_64
    elif [ -n "${CXX_32:-}" ] ; then
      export CXX=$CXX_32
    fi
  fi

  _read_props "post.properties"
  
  [ "$old_CMAKE_CFG" != "_none_" ] && CMAKE_CFG="$old_CMAKE_CFG"
  [ "$old_CFG" != "_none_" ] && CFG="$old_CFG"
  [ "$old_CFG_ENV" != "_none_" ] && CFG_ENV="$old_CFG_ENV"
  [ "$old_COMPILE_OPTS" != "_none_" ] && COMPILE_OPTS="$old_COMPILE_OPTS"
  [ "$old_COPY_OPTS" != "_none_" ] && COPY_OPTS="$old_COPY_OPTS"
  [ "$old_PATCH_OPTS" != "_none_" ] && PATCH_OPTS="$old_PATCH_OPTS"
  
  unpack_script=$(_exec unpack)
  fix_script=$(_exec fix)
  config_script=$(_exec config)
  cmake_script=$(_exec cmake)
  compile_script=$(_exec compile)
  prepare_script=$(_exec prepare)
  copy_script=$(_exec copy)
}

function exp() {
  export
}

function dump() {
  echo "ARCH                 : $ARCH"
  echo "USE_ARCH             : ${USE_ARCH:-}"
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
  echo "CMAKE_CFG            : $CMAKE_CFG"
  echo "CC                   : ${CC:-}"
  echo "CXX                  : ${CXX:-}"
  echo "PKG_CONFIG_PATH      : ${PKG_CONFIG_PATH:-}"
  echo
  _dump_script "$unpack_script"
  _dump_script "$fix_script"
  _dump_script "$config_script"
  _dump_script "$prepare_script"
  _dump_script "$compile_script"
  _dump_script "$copy_script"
}

function aide {
  echo "STEP: aide"

  if [ "$IDLE_CONFIG" == "mk" ] ; then
    _clean_build_dir_and_cd
    cmake -LAH $PKG_SRC_DIR
  else
    $PKG_CFG_DIR/configure --help
  fi
}

function unpack() {
  echo "STEP: unpack"

  if [ -n "$unpack_script" ] ; then 
    eval "$unpack_script" 
  else
    rm -fr $PKG_SRC_DIR 2>/dev/null || true
    tar xf $1 -C $(dirname $PKG_SRC_DIR)
  fi
}

# Patch file name may inlcude phase name, arch name or none of them:
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
    echo "Applying patches from $patch_file_path"
    unxz -c "$patch_file_path" | patch $PATCH_OPTS
  fi
  
  if [ -n "$fix_script" ] ; then 
    eval "$fix_script" 
  fi
}

function config() {
  echo "STEP: config"
  
  _clean_build_dir_and_cd
  
  if [ -n "$config_script" ] ; then 
    eval "$config_script" 
  else
    if [ "$IDLE_CONFIG" == "mk" ] ; then
      eval "cmake $CMAKE_CFG $PKG_SRC_DIR"
    else
      eval "$CFG_ENV $PKG_CFG_DIR/configure $CFG"
    fi
  fi
}

function prepare() {
  cd $PKG_SRC_DIR
  if [ -n "$prepare_script" ] ; then 
    echo "STEP: prepare"

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

  rm -fr $DST_DIR/$PKG_LONG_NAME/$PREFIX/{,share}/{info,doc,gtk-doc}
  
  [ "$DROP_MAN" == "true" ] && rm -fr $DST_DIR/$PKG_LONG_NAME/$PREFIX/share/man
  [ "$DROP_LOCALE" == "true" ] && rm -fr $DST_DIR/$PKG_LONG_NAME/$PREFIX/share/locale
  
  if [ -d "$DST_DIR/$PKG_LONG_NAME/$PREFIX/share/pkgconfig" ] ; then
    mkdir -pv $DST_DIR/$PKG_LONG_NAME/$PREFIX/lib$LIB_SUFFIX
    mv $DST_DIR/$PKG_LONG_NAME/$PREFIX/share/pkgconfig $DST_DIR/$PKG_LONG_NAME/$PREFIX/lib$LIB_SUFFIX
  fi

  if [ -d $DST_DIR/$PKG_LONG_NAME/$PREFIX/share/pkgconfig ] ; then
    if [ -n "$(command ls -1 $DST_DIR/$PKG_LONG_NAME/$PREFIX/share/pkgconfig)" ] ; then
      mkdir -p $DST_DIR/$PKG_LONG_NAME/$PREFIX/lib$LIB_SUFFIX/pkgconfig
      cp -r $DST_DIR/$PKG_LONG_NAME/$PREFIX/share/pkgconfig/* $DST_DIR/$PKG_LONG_NAME/$PREFIX/lib$LIB_SUFFIX/pkgconfig
    fi
    rm -fr $DST_DIR/$PKG_LONG_NAME/$PREFIX/share/pkgconfig
  fi

  if [ -d "$DST_DIR/$PKG_LONG_NAME/$PREFIX/share" ] ; then
    [ -z "$(command ls -1 $DST_DIR/$PKG_LONG_NAME/$PREFIX/share)" ] && rm -fr $DST_DIR/$PKG_LONG_NAME/$PREFIX/share
  fi
  if [ -d "$DST_DIR/$PKG_LONG_NAME/$PREFIX" ] ; then
    [ -z "$(command ls -1 $DST_DIR/$PKG_LONG_NAME/$PREFIX)" ] && rm -fr $DST_DIR/$PKG_LONG_NAME/$PREFIX
  fi
  
  if [ -d $DST_DIR/$PKG_LONG_NAME/lib32 ] ; then
    if [ -n "$(command ls -1 $DST_DIR/$PKG_LONG_NAME/lib32)" ] ; then
      mkdir -p $DST_DIR/$PKG_LONG_NAME/$PREFIX/lib32
      cp -r $DST_DIR/$PKG_LONG_NAME/lib32/* $DST_DIR/$PKG_LONG_NAME/$PREFIX/lib32
    fi
    rm -fr $DST_DIR/$PKG_LONG_NAME/lib32
  fi
  if [ -d $DST_DIR/$PKG_LONG_NAME/lib64 ] ; then
    if [ -n "$(command ls -1 $DST_DIR/$PKG_LONG_NAME/lib64)" ] ; then
      mkdir -p $DST_DIR/$PKG_LONG_NAME/$PREFIX/lib64
      cp -r $DST_DIR/$PKG_LONG_NAME/lib64/* $DST_DIR/$PKG_LONG_NAME/$PREFIX/lib64
    fi  
    rm -fr $DST_DIR/$PKG_LONG_NAME/lib64
  fi
  if [ -d $DST_DIR/$PKG_LONG_NAME/$PREFIX/sbin ] ; then
    if [ -n "$(command ls -1 $DST_DIR/$PKG_LONG_NAME/$PREFIX/sbin)" ] ; then
      mkdir -p $DST_DIR/$PKG_LONG_NAME/$PREFIX/bin
      cp -r $DST_DIR/$PKG_LONG_NAME/$PREFIX/sbin/* $DST_DIR/$PKG_LONG_NAME/$PREFIX/bin
    fi
    rm -fr $DST_DIR/$PKG_LONG_NAME/$PREFIX/sbin
  fi
  if [ -d $DST_DIR/$PKG_LONG_NAME/sbin ] ; then
    if [ -n "$(command ls -1 $DST_DIR/$PKG_LONG_NAME/sbin)" ] ; then
      mkdir -p $DST_DIR/$PKG_LONG_NAME/$PREFIX/bin
      cp -r $DST_DIR/$PKG_LONG_NAME/sbin/* $DST_DIR/$PKG_LONG_NAME/$PREFIX/bin
    fi
    rm -fr $DST_DIR/$PKG_LONG_NAME/sbin
  fi
  if [ -d $DST_DIR/$PKG_LONG_NAME/bin ] ; then
    if [ -n "$(command ls -1 $DST_DIR/$PKG_LONG_NAME/bin)" ] ; then
      mkdir -p $DST_DIR/$PKG_LONG_NAME/$PREFIX/bin
      cp -r $DST_DIR/$PKG_LONG_NAME/bin/* $DST_DIR/$PKG_LONG_NAME/$PREFIX/bin
    fi
    rm -fr $DST_DIR/$PKG_LONG_NAME/bin
  fi
  
  if [ -d "$DST_DIR/$PKG_LONG_NAME/$PREFIX/bin" ] ; then
    [ -z "$(command ls -1 $DST_DIR/$PKG_LONG_NAME/$PREFIX/bin)" ] && rm -fr $DST_DIR/$PKG_LONG_NAME/$PREFIX/bin
  fi
  if [ -d "$DST_DIR/$PKG_LONG_NAME/$PREFIX/sbin" ] ; then
    [ -z "$(command ls -1 $DST_DIR/$PKG_LONG_NAME/$PREFIX/sbin)" ] && rm -fr $DST_DIR/$PKG_LONG_NAME/$PREFIX/sbin
  fi

  find $DST_DIR/$PKG_LONG_NAME/$PREFIX/{,usr/}{bin,sbin,lib,lib32,lib64} -type f -exec strip --strip-debug '{}' ';' 2>/dev/null || true
  
  if [ -n "${WRAP:-}" ] ; then
    for f in $WRAP ; do
      local _fullfilename="$DST_DIR/$PKG_LONG_NAME/$f"
      local _filedirname="$(dirname $_fullfilename)"
      local _filename="$(basename $_fullfilename)"
      
      local _name="$(echo $_filename | sed -r -e 's,([^.]+)(\..*)?,\1,')"
      local _postfix="$(echo $_filename | sed -r -e 's,([^.]+)(\..*)?,\2,')"
    
      mv -v $_fullfilename "${_filedirname}/${_name}-$ARCH$_postfix"
      ln -sfv multiarch_wrapper $_fullfilename
    done
  fi
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