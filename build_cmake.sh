#!/bin/bash

rm -rf build
mkdir build

docker run --pull always -ti --rm -v `pwd`/sample:/project/source -v `pwd`/build:/project/build forderud/qtwasm:qt6.5 || exit 1
