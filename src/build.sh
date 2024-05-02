#!/bin/bash

set -e

# note - autoconf, automake, libtool required here

PREFIX="$(pwd)/build/usr"

cd build/pjproject

# build pjproject

cp pjlib/include/pj/config_site_sample.h pjlib/include/pj/config_site.h
echo "#define PJMEDIA_HAS_VID_TOOLBOX_CODEC 1" >> pjlib/include/pj/config_site.h
./configure --prefix=$PREFIX CFLAGS="-g -Og" LDFLAGS="-g"
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
swig -I../usr/include -javascript -napi -typescript -c++ -o ../swig/pjsua2_wrap.cpp pjsip-apps/src/swig/pjsua2.i
mv ../swig/pjsua2.d.ts ../swig/binding.d.ts