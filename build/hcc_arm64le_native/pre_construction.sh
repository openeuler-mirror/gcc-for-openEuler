#!/bin/bash
# This script is used to create a temporary directory,
# unzip and patch the source package.
# Copyright (c) Huawei Technologies Co., Ltd. 2023-2023. All rights reserved.

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
tar -xf $ROOT_BUILD_DIR/open_source/gmp/$GMP.tar.xz -C $ROOT_NATIVE_SRC
tar -xf $ROOT_BUILD_DIR/open_source/texinfo/$TEXINFO.tar.xz -C $ROOT_NATIVE_SRC
tar -xf $ROOT_BUILD_DIR/open_source/mpfr/$MPFR.tar.xz -C $ROOT_NATIVE_SRC
tar -xzf $ROOT_BUILD_DIR/open_source/libmpc/$MPC.tar.gz -C $ROOT_NATIVE_SRC
tar -xzf $ROOT_BUILD_DIR/open_source/isl/$ISL.tar.gz -C $ROOT_NATIVE_SRC
tar -xzf $ROOT_BUILD_DIR/open_source/optimized-routines/$MATHLIB.tar.gz -C $ROOT_NATIVE_SRC
tar -xf $ROOT_BUILD_DIR/open_source/jemalloc/$JEMALLOC.tar.bz2 -C $ROOT_NATIVE_SRC
tar -xf $ROOT_BUILD_DIR/open_source/autofdo/$AUTOFDO.tar.xz -C $ROOT_NATIVE_SRC
tar -xf $ROOT_BUILD_DIR/open_source/llvm-bolt/$BOLT.tar.xz -C $ROOT_NATIVE_SRC
tar -xzf $ROOT_BUILD_DIR/open_source/cmake/$CMAKE.tar.gz -C $ROOT_NATIVE_SRC
tar -xzf $ROOT_BUILD_DIR/open_source/AI4C/$AI4C.tar.gz -C $ROOT_NATIVE_SRC
tar -xzf $ROOT_BUILD_DIR/open_source/yaml-cpp/$YAML_CPP.tar.gz -C $ROOT_NATIVE_SRC
tar -xzf $ROOT_BUILD_DIR/open_source/openssl/$OPENSSL.tar.gz -C $ROOT_NATIVE_SRC
tar -xzf $ROOT_BUILD_DIR/open_source/ncurses/$NCURSES.tar.gz -C $ROOT_NATIVE_SRC
tar -xf $ROOT_BUILD_DIR/open_source/llvm/$LLVM_CMAKE.tar.xz -C $ROOT_NATIVE_SRC
tar -xf $ROOT_BUILD_DIR/open_source/llvm/$LLVM_THIRD_PARTY.tar.xz -C $ROOT_NATIVE_SRC
tar -xf $ROOT_BUILD_DIR/open_source/llvm-mlir/$MLIR.tar.xz -C $ROOT_NATIVE_SRC
tar -xzf $ROOT_BUILD_DIR/open_source/protobuf/${PROTOBUF/-/-all-}.tar.gz -C $ROOT_NATIVE_SRC
tar -xzf $ROOT_BUILD_DIR/open_source/pin-gcc-client/$GCC_CLIENT.tar.gz -C $ROOT_NATIVE_SRC
tar -xzf $ROOT_BUILD_DIR/open_source/grpc/$GRPC.tar.gz -C $ROOT_NATIVE_SRC
tar -xzf $ROOT_BUILD_DIR/open_source/c-ares/$CARES.tar.gz -C $ROOT_NATIVE_SRC
tar -xzf $ROOT_BUILD_DIR/open_source/abseil-cpp/$ABSEIL.tar.gz -C $ROOT_NATIVE_SRC
tar -xzf $ROOT_BUILD_DIR/open_source/re2/${RE2#*-}.tar.gz -C $ROOT_NATIVE_SRC
tar -xzf $ROOT_BUILD_DIR/open_source/jsoncpp/$JSONCPP.tar.gz -C $ROOT_NATIVE_SRC
tar -xf $ROOT_BUILD_DIR/open_source/perl/$PERL.tar.xz -C $ROOT_NATIVE_SRC
tar -xf $ROOT_BUILD_DIR/open_source/perl-IPC-Cmd/$PERL_IPC_CMD.tar.gz -C $ROOT_NATIVE_SRC
unzip $ROOT_BUILD_DIR/open_source/BiSheng-opentuner/bisheng-opentuner.zip -d $ROOT_NATIVE_SRC
unzip $ROOT_BUILD_DIR/open_source/BiSheng-Autotuner/BiSheng-Autotuner.zip -d $ROOT_NATIVE_SRC

apply_patch() {
    echo "applying patch for $1......"
    if [ $1 = "isl" ]; then
        cd $ROOT_NATIVE_SRC
    else
        cd $ROOT_NATIVE_SRC/$2
    fi
    if [ $1 = "binutils" ]; then
        for file in $(grep -ne '^Patch[0-9]\{1,2\}:.*\.patch' $ROOT_BUILD_DIR/open_source/$1/$1.spec | awk '{print $2}'); do
            patch --fuzz=0 -p1 <$ROOT_BUILD_DIR/open_source/$1/$file
        done
    elif [ $1 = "gcc" ]; then
	for file in $(grep -ne '^Patch[0-9]\{1,3\}:.*\.patch' $ROOT_BUILD_DIR/open_source/$1/$1.spec | awk '{print $2}'); do
            patch --fuzz=0 -p1 <$ROOT_BUILD_DIR/open_source/$1/$file
        done
    elif [ $1 = "AI4C" ]; then
        for file in $(grep -ne '^Patch[0-9]*:.*\.patch' $ROOT_BUILD_DIR/open_source/$1/$1.spec | awk '{print $2}'); do
	    git apply -p1 < $ROOT_BUILD_DIR/open_source/$1/$file
        done
    elif [ $1 = "cmake" ]; then
        for file in $(grep -ne '^Patch[02]:.*\.patch' $ROOT_BUILD_DIR/open_source/$1/$1.spec | awk '{print $2}'); do
            patch --fuzz=0 -p1 <$ROOT_BUILD_DIR/open_source/$1/$file
        done
    else
        for file in $(grep -ne ^Patch[0-9]*:.*\.patch $ROOT_BUILD_DIR/open_source/$1/*.spec | awk '{print $2}'); do
            patch --fuzz=0 -p1 <$ROOT_BUILD_DIR/open_source/$1/$file
        done
    fi
    cd -
}

apply_patch gcc $GCC
apply_patch binutils $BINUTILS
apply_patch gmp $GMP
apply_patch libmpc $MPC
apply_patch mpfr $MPFR
apply_patch isl $ISL
apply_patch optimized-routines $MATHLIB
apply_patch jemalloc $JEMALLOC
apply_patch autofdo $AUTOFDO
apply_patch llvm-bolt $BOLT
apply_patch cmake $CMAKE
apply_patch AI4C $AI4C
mv $ROOT_NATIVE_SRC/yaml-cpp-$YAML_CPP $ROOT_NATIVE_SRC/$YAML_CPP
apply_patch yaml-cpp $YAML_CPP
apply_patch openssl $OPENSSL
apply_patch ncurses $NCURSES
mv $ROOT_NATIVE_SRC/$LLVM_CMAKE $ROOT_NATIVE_SRC/cmake
mv $ROOT_NATIVE_SRC/$LLVM_THIRD_PARTY $ROOT_NATIVE_SRC/third-party
# skip mlir patch
apply_patch protobuf $PROTOBUF
apply_patch pin-gcc-client $GCC_CLIENT
apply_patch grpc $GRPC
apply_patch jsoncpp $JSONCPP
apply_patch c-ares $CARES
rm -rf $ROOT_NATIVE_SRC/$GRPC/third_party/cares/cares
mv $ROOT_NATIVE_SRC/$CARES $ROOT_NATIVE_SRC/$GRPC/third_party/cares/cares

apply_patch abseil-cpp $ABSEIL
rm -rf $ROOT_NATIVE_SRC/$PROTOBUF/third_party/abseil-cpp
mv $ROOT_NATIVE_SRC/$ABSEIL $ROOT_NATIVE_SRC/$PROTOBUF/third_party/abseil-cpp

apply_patch re2 $RE2
rm -rf $ROOT_NATIVE_SRC/$GRPC/third_party/re2
mv $ROOT_NATIVE_SRC/$RE2 $ROOT_NATIVE_SRC/$GRPC/third_party/re2

# skip perl patch
apply_patch perl-IPC-Cmd $PERL_IPC_CMD
apply_patch BiSheng-opentuner $OPEN_TUNER
apply_patch BiSheng-Autotuner $AUTO_TUNER

chmod 777 $ROOT_NATIVE_SRC -R
