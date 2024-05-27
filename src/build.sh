#!/bin/bash

set -e

# note - autoconf, automake, libtool required here

PREFIX="$(pwd)/build/usr"

cd build/pjproject

# build pjproject

if [ "$BUILDTYPE" == "Debug" ] ; then
    if [ "$(uname)" == "Darwin" ] ; then
        CFLAGS="-fPIC -O0 -g"
    else 
        CFLAGS="-fPIC -0g -g"
    fi
    LDFLAGS="-g"
else
    CFLAGS="-fPIC"
    LDFLAGS=""
fi
cp pjlib/include/pj/config_site_sample.h pjlib/include/pj/config_site.h
echo "#define PJMEDIA_HAS_VID_TOOLBOX_CODEC 1" >> pjlib/include/pj/config_site.h
./configure --prefix=$PREFIX CFLAGS="$CFLAGS" LDFLAGS="$LDFLAGS"
make -j 4
make install

# build master library

cd ../usr/lib
PREFIX=""
COUNTER="1"
while [ "$(ls -1 *.a | rev | cut -c -$COUNTER | uniq -c | wc -l)" -eq "1" ]
do
    PREFIX=$(ls -1 *.a | head -n 1 | rev | cut -c -$COUNTER | rev)
    COUNTER=$[$COUNTER+1]
done
for a in *.a ; do mv "$a" "$(echo $a | rev | cut -c $COUNTER- | rev).a" ; done
cd ../../pjproject

# build the wrapper

mkdir -p ../swig
swig -v -I../usr/include -I../../src -javascript -napi -typescript -c++ -o ../swig/pjsua2_wrap.cpp ../../src/callback.i
../../src/pp-swig.sh
mv ../swig/callback.d.ts ../swig/binding.d.ts

# work around issue where using node-gyp to copy files seems to turn the original into a symlink, which
# breaks npm package!

cd ../..
mkdir -p build/binding
cp src/binding.js build/binding
