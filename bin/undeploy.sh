#!/bin/bash

set -e
set -u
set +h

package=$(basename $1)

if [ ! -r "/var/cache/idle/dst/${package}" ] ; then 
  echo "File /var/cache/idle/dst/${package} not found"
  
  exit -1
fi

echo "Undeploying /var/cache/idle/dst/${package}"

tar tf /var/cache/idle/dst/${package} | while read file ; do
  if [ ! -d "/$file" ] ; then
    if [ -r "/$file" ] || [ -L "/$file" ] ; then
      rm -v "/$file"
    fi
  fi
done

tar tf /var/cache/idle/dst/${package} | sort -r | while read file ; do
  if [ -d "/$file" ] ; then
    if [ -z "`command ls /$file`" ] ; then
      rm -rv "/$file"
    fi
  fi
done
