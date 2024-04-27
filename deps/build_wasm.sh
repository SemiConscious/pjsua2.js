#!/bin/sh

unset MAKEFLAGS
unset SDKROOT

EMSDK_PATH=`cat ../conan/conan_emsdk.path`
. ${EMSDK_PATH}/bin/emsdk_env.sh

cd pjproject

emmake make -j4
make install
# XXX
rm -rf $1/pjsua/lib/*.*a
