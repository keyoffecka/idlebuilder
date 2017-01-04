#!/bin/bash

#Should be executed mannually once after GLibC x86_64 has been installed

set +h
set -e
set -u

$TOOLS_DIR/bin/gcc -dumpspecs | \
perl -p -e 's@/tools/lib32/ld@/lib32/ld@g;' \
        -e 's@/tools/lib64/ld@/lib64/ld@g;' \
        -e 's@\*startfile_prefix_spec:\n@$_/usr/lib64/ @g;' > $(dirname $($TOOLS_DIR/bin/gcc --print-libgcc-file-name))/specs
