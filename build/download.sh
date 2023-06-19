#!/bin/bash
# Download all the required packages.
# Copyright (c) Huawei Technologies Co., Ltd. 2022-2022. All rights reserved.

set -e

source $PWD/config.xml

readonly OPEN_SOURCE_PATH="$PWD/../open_source"
readonly GCC_NAME="gcc"
readonly BINUTILS_NAME="binutils"
readonly GMP_NAME="gmp"
readonly MPC_NAME="libmpc"
readonly MPFR_NAME="mpfr"
readonly ISL_NAME="isl"
readonly MATHLIB_NAME="optimized-routines"
readonly JEMALLOC_NAME="jemalloc"
readonly AUTOFDO_NAME="autofdo"
readonly BOLT_NAME="llvm-bolt"
readonly CMAKE_NAME="cmake"
readonly OPENSSL_NAME="openssl"

# Create the open source software directory.
[ ! -d "$OPEN_SOURCE_PATH" ] && mkdir $OPEN_SOURCE_PATH

download() {
    [ -d "$1" ] && rm -rf $1
    echo "Download $1." && git clone -b $BRANCH https://gitee.com/src-openeuler/$1.git
}

# Download packages.
pushd $OPEN_SOURCE_PATH

download $GCC_NAME
download $BINUTILS_NAME
download $GMP_NAME
download $MPC_NAME
download $MPFR_NAME
download $ISL_NAME
download $MATHLIB_NAME
download $JEMALLOC_NAME
download $AUTOFDO_NAME
download $BOLT_NAME
download $CMAKE_NAME
download $OPENSSL_NAME

popd
echo "Download success!!!"
