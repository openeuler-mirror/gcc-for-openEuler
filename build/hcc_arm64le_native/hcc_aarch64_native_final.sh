#!/bin/bash
# This file contains the complete sequence of commands
# to build the toolchain, including the configuration
# options and compilation processes.
# Copyright (c) Huawei Technologies Co., Ltd. 2022-2022. All rights reserved.

set -e

# Environment variables that never change during the build process.
if [[ -z "$COMPILER_INFO" ]]; then
    source $PWD/../config.xml
fi

# Target root directory, should be adapted according to your environment.
readonly ROOT_NATIVE_DIR="$PWD/arm64le_build_dir"
readonly ROOT_NATIVE_SRC="$PWD/../../open_source/hcc_arm64le_native_build_src"
readonly PREFIX_NATIVE="$PWD/arm64le_build_dir/$INSTALL_NATIVE"
readonly OUTPUT="$PWD/../../output/$INSTALL_NATIVE"
readonly PARALLEL=$(grep ^processor /proc/cpuinfo | wc -l)

declare -x SECURE_CFLAGS="-O2 -fPIC -Wall -fstack-protector-strong -D_FORTIFY_SOURCE=2 -Wl,-z,relro,-z,now,-z,noexecstack -Wtrampolines -mlittle-endian -march=armv8-a"
declare -x PATH=$PREFIX_NATIVE/bin:$PATH
declare -x CFLAGS_FOR_MATHLIB="-frounding-math -fexcess-precision=standard $SECURE_CFLAGS"
declare -x CFLAGS_FOR_JEMALLOC="$SECURE_CFLAGS"

echo "Building mathlib..." && pushd "${ROOT_NATIVE_DIR}/obj/build-mathlib"
ln -sf "${ROOT_NATIVE_SRC}/${MATHLIB}/Makefile" Makefile
cp -f "${ROOT_NATIVE_SRC}/${MATHLIB}/config.mk.dist" config.mk
echo "srcdir = ${ROOT_NATIVE_SRC}/${MATHLIB}" >>config.mk
echo "string-cflags += ${CFLAGS_FOR_MATHLIB}" >>config.mk
echo "math-cflags += ${CFLAGS_FOR_MATHLIB}" >>config.mk
echo "CFLAGS += ${CFLAGS_FOR_MATHLIB}" >>config.mk
sed -i "s/SUBS = math string networking/SUBS = math string/g" config.mk
sed -i "s@prefix = /usr@prefix = ${PREFIX_NATIVE}@" Makefile
sed -i "s@libdir = \$(prefix)/lib@libdir = \$(prefix)/lib64@" Makefile
make -j $PARALLEL && make install && popd

echo "Building jemalloc..." && pushd $ROOT_NATIVE_SRC/$JEMALLOC
autoconf
popd
pushd $ROOT_NATIVE_DIR/obj/build-jemalloc
LDFLAGS="${CFLAGS_FOR_JEMALLOC}" CFLAGS="${CFLAGS_FOR_JEMALLOC}" CXXFLAGS="${CFLAGS_FOR_JEMALLOC}" $ROOT_NATIVE_SRC/$JEMALLOC/configure --prefix=$PREFIX_NATIVE --enable-autogen --with-lg-page=21
sed -i "s@LIBDIR := \$(DESTDIR)${PREFIX_NATIVE}/lib@LIBDIR := \$(DESTDIR)${PREFIX_NATIVE}/lib64@" Makefile
sed -i "s@EXTRA_CFLAGS :=@EXTRA_CFLAGS := -shared@" Makefile
sed -i "s@EXTRA_CXXFLAGS :=@EXTRA_CXXFLAGS := -shared@" Makefile
make -j $PARALLEL && make install && popd

find $PREFIX_NATIVE -name "*.la" -exec rm -f {} \;

find $PREFIX_NATIVE -name "*.so*" -exec sh -c 'file -ib {} | grep -q "sharedlib" && chrpath --delete {}' \;
echo "End of dir chrpath trim."

find $PREFIX_NATIVE -type f -exec sh -c 'file -ib {} | grep -qE "sharedlib|executable" && /usr/bin/strip --strip-unneeded {}' \;
echo "End of libraries and executables strip."

pushd $PREFIX_NATIVE/.. && chmod 750 $INSTALL_NATIVE -R
tar --format=gnu -czf $OUTPUT/$INSTALL_NATIVE.tar.gz $INSTALL_NATIVE && popd

echo "Build Complete!" && echo "To use this newly-built $INSTALL_NATIVE cross toolchain, add $PREFIX_NATIVE/bin to your PATH!"
