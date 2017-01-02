#!/bin/bash

set +h
set -e
set -u

source $WORKDIR/share/builders/functions.sh

case "$#" in
  0)
    echo "Wrong argument count"
    exit -1
  ;;

  1)
    initialize "$(basename $0)" "$1"
    dump
    _ask
    unpack "$1"
    fix
    config
    prepare
    compile
    copy
    clean
    _ask
    package
    deploy
  ;;
  
  *)
    src_pkg_file_name="$1"
  
    initialize "$(basename $0)" "$src_pkg_file_name"

    shift
    
    while (( $# )); do
      if [ "$1" == "initialize" ] ; then
        echo "The 'initilize' task is always called at the very beginning and shouldn't be called explicitly."
        exit -2
      fi

      eval "$1 \"$src_pkg_file_name\""
      
      shift
    done
  ;;

esac

