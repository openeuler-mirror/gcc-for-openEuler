#!/bin/bash
# Download all the required packages.
# Copyright (c) Huawei Technologies Co., Ltd. 2023-2023. All rights reserved.

set -e

source $PWD/config.xml

readonly OPEN_SOURCE_PATH="$PWD/../open_source"
readonly GCC_NAME="gcc"
readonly BINUTILS_NAME="binutils"
readonly GMP_NAME="gmp"
readonly TEXINFO_NAME="texinfo"
readonly MPC_NAME="libmpc"
readonly MPFR_NAME="mpfr"
readonly ISL_NAME="isl"
readonly MATHLIB_NAME="optimized-routines"
readonly JEMALLOC_NAME="jemalloc"
readonly AUTOFDO_NAME="autofdo"
readonly BOLT_NAME="llvm-bolt"
readonly CMAKE_NAME="cmake"
readonly AI4C_NAME="AI4C"
readonly YAML_CPP_NAME="yaml-cpp"
readonly OPENSSL_NAME="openssl"
readonly NCURSES_NAME="ncurses"
readonly LLVM_NAME="llvm"
readonly MLIR_NAME="llvm-mlir"
readonly PROTOBUF_NAME="protobuf"
readonly PIN_GCC_CLIENT_NAME="pin-gcc-client"
readonly GRPC_NAME="grpc"
readonly CARES_NAME="c-ares"
readonly ABSEIL_NAME="abseil-cpp"
readonly RE2_NAME="re2"
readonly JSONCPP_NAME="jsoncpp"
readonly PERL_NAME="perl"
readonly PERL_IPC_CMD_NAME="perl-IPC-Cmd"
readonly OPEN_TUNER="BiSheng-opentuner"
readonly AUTO_TUNER="BiSheng-Autotuner"

# Create the open source software directory.
[ ! -d "$OPEN_SOURCE_PATH" ] && mkdir $OPEN_SOURCE_PATH

pip3 install $PWD/*.whl

download() {
    [ -d "$1" ] && rm -rf $1
    echo "Download $1." && git clone -b $BRANCH https://gitee.com/src-openeuler/$1.git --depth=1
}

# Download packages.
pushd $OPEN_SOURCE_PATH

download $GCC_NAME
download $BINUTILS_NAME
download $GMP_NAME
download $TEXINFO_NAME
download $MPC_NAME
download $MPFR_NAME
download $ISL_NAME
download $MATHLIB_NAME
download $JEMALLOC_NAME
download $AUTOFDO_NAME
download $BOLT_NAME
download $CMAKE_NAME
download $AI4C_NAME
download $YAML_CPP_NAME
download $OPENSSL_NAME
download $NCURSES_NAME
download $LLVM_NAME
download $MLIR_NAME
download $PROTOBUF_NAME
download $PIN_GCC_CLIENT_NAME
download $GRPC_NAME
download $CARES_NAME
download $ABSEIL_NAME
download $RE2_NAME
download $JSONCPP_NAME
download $PERL_NAME
download $PERL_IPC_CMD_NAME
download $OPEN_TUNER
download $AUTO_TUNER

popd
echo "Download success!!!"
