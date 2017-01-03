#!/bin/bash

#Should be executed mannualy once before starting the phase 3

set +h
set -e
set -u

cd $(dirname $0)/..

rm $ROOT/usr/lib64/libstd* || true
rm $ROOT/usr/lib32/libstd* || true

ln -sfv ../../$TOOLS_DIR/bin/{bash,cat,echo,grep,pwd,stty} $ROOT/usr/bin
ln -sfv ../../$TOOLS_DIR/bin/file $ROOT/usr/bin
ln -sfv ../../$TOOLS_DIR/lib32/libgcc_s.so{,.1} $ROOT/usr/lib32
ln -sfv ../../$TOOLS_DIR/lib64/libgcc_s.so{,.1} $ROOT/usr/lib64
ln -sv ../../$TOOLS_DIR/lib32/libstd* $ROOT/usr/lib32
ln -sv ../../$TOOLS_DIR/lib64/libstd* $ROOT/usr/lib64
ln -sfv bash $ROOT/usr/bin/sh
