#!/bin/bash
# This script is used to create a temporary directory,
# unzip and patch the source package.
# Copyright (c) Huawei Technologies Co., Ltd. 2022-2022. All rights reserved.

set -e

if [[ -z "$COMPILER_INFO" ]]; then
    source $PWD/../config.xml
fi

readonly ROOT_BUILD_DIR="$PWD/../.."
readonly ROOT_NATIVE_SRC="$PWD/../../open_source/hcc_arm64le_native_build_src"
readonly OUTPUT="$PWD/../../output/$INSTALL_NATIVE"

# Clear history build legacy files.
clean() {
    [ -n "$ROOT_NATIVE_SRC" ] && rm -rf $ROOT_NATIVE_SRC
    [ -n "$OUTPUT" ] && rm -rf $OUTPUT
    mkdir -p $ROOT_NATIVE_SRC $OUTPUT
}

# Clean the build directory.
clean

# Unzip the source package and copy the source files.
tar -xf $ROOT_BUILD_DIR/open_source/gcc/$GCC.tar.xz -C $ROOT_NATIVE_SRC
tar -xf $ROOT_BUILD_DIR/open_source/binutils/$BINUTILS.tar.xz -C $ROOT_NATIVE_SRC
tar -xf $ROOT_BUILD_DIR/open_source/gmp/$GMP.tar.bz2 -C $ROOT_NATIVE_SRC
tar -xf $ROOT_BUILD_DIR/open_source/mpfr/$MPFR.tar.xz -C $ROOT_NATIVE_SRC
tar -xzf $ROOT_BUILD_DIR/open_source/libmpc/$MPC.tar.gz -C $ROOT_NATIVE_SRC
tar -xf $ROOT_BUILD_DIR/open_source/isl/$ISL.tar.xz -C $ROOT_NATIVE_SRC
tar -xf $ROOT_BUILD_DIR/open_source/isl/$OLD_ISL.tar.xz -C $ROOT_NATIVE_SRC
tar -xf $ROOT_BUILD_DIR/open_source/jemalloc/$JEMALLOC.tar.bz2 -C $ROOT_NATIVE_SRC
tar -xzf $ROOT_BUILD_DIR/open_source/optimized-routines/$MATHLIB.tar.gz -C $ROOT_NATIVE_SRC
tar -xf $ROOT_BUILD_DIR/open_source/autofdo/$AUTOFDO.tar.xz -C $ROOT_NATIVE_SRC
tar -xf $ROOT_BUILD_DIR/open_source/llvm-bolt/$BOLT.tar.xz -C $ROOT_NATIVE_SRC
tar -xzf $ROOT_BUILD_DIR/open_source/cmake/$CMAKE.tar.gz -C $ROOT_NATIVE_SRC
tar -xzf $ROOT_BUILD_DIR/open_source/openssl/$OPENSSL.tar.gz -C $ROOT_NATIVE_SRC

apply_patch() {
    if [ $1 = "isl" ]; then
        cd $ROOT_NATIVE_SRC
    else
        cd $ROOT_NATIVE_SRC/$2
    fi
    for file in $(grep -ne ^Patch[0-9]*:.*\.patch $ROOT_BUILD_DIR/open_source/$1/$1.spec | awk '{print $2}'); do
        patch --fuzz=0 -p1 <$ROOT_BUILD_DIR/open_source/$1/$file
    done
    cd -
}

apply_patch gcc $GCC
apply_patch binutils $BINUTILS
apply_patch gmp $GMP
apply_patch mpfr $MPFR
apply_patch libmpc $MPC
apply_patch isl $ISL
apply_patch jemalloc $JEMALLOC
apply_patch optimized-routines $MATHLIB
apply_patch autofdo $AUTOFDO
apply_patch llvm-bolt $BOLT
apply_patch cmake $CMAKE
apply_patch openssl $OPENSSL

chmod 777 $ROOT_NATIVE_SRC -R
