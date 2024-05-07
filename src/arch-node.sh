#!/bin/bash

set -e

ARCH=$1
VER=$2
PLATFORM=$3

rm -rf /tmp/nodejs
mkdir -p /tmp/nodejs/src
mkdir -p /tmp/nodejs/Release

pushd /tmp/nodejs/Release
curl -s https://nodejs.org/download/release/$VER/$ARCH/node.lib
cd ../src
curl -s https://nodejs.org/download/release/$VER/node-$VER-headers.tar.gz
unzip node-$VER-headers.tar.gz
mv *.gypi ..
popd
