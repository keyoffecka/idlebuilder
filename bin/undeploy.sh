#!/bin/bash

set -e
set -u
set +h

package_path="$1"

if [ ! -r "$package_path" ] ; then
  package_path="/var/cache/idle/dst/$(basename $1)"
fi

if [ ! -r  ] ; then 
  echo "File $package_path not found"
  
  exit -1
fi

echo "Undeploying $package_path"

tar tf $package_path | while read file ; do
  if [ ! -d "/$file" ] ; then
    if [ -r "/$file" ] || [ -L "/$file" ] ; then
      rm -v "/$file"
    fi
  fi
done

tar tf $package_path | sort -r | while read file ; do
  if [ -d "/$file" ] ; then
    if [ -z "`command ls /$file`" ] ; then
      rm -rv "/$file"
    fi
  fi
done
