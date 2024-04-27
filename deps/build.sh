#!/bin/sh

unset MAKEFLAGS
unset SDKROOT

cd pjproject

make -j4
make install
# XXX
rm -rf $1/pjproject/lib/*.*a
