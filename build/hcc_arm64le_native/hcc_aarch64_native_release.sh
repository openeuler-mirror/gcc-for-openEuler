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
readonly PREFIX_BOLT="$PWD/arm64le_build_dir/llvm-bolt"
readonly PREFIX_OPENSSL="$PWD/arm64le_build_dir/openssl"
readonly OUTPUT="$PWD/../../output/$INSTALL_NATIVE"
readonly PARALLEL=$(grep ^processor /proc/cpuinfo | wc -l)
readonly HOST="aarch64-linux-gnu"
readonly BUILD=$HOST
readonly TARGET=$HOST

declare -x SECURE_CFLAGS="-O2 -fPIC -Wall -fstack-protector-strong -D_FORTIFY_SOURCE=2 -Wl,-z,relro,-z,now,-z,noexecstack -Wtrampolines -mlittle-endian -march=armv8-a"
declare -x SECURE_LDFLAGS="-z relro -z now -z noexecstack"
declare -x FCFLAGS="$SECURE_CFLAGS"

# Create an empty directory.
create_directory() {
    while [ $# != 0 ]; do
        [ -n "$1" ] && rm -rf $1
        mkdir -p $1
        shift
    done
}

create_directory $ROOT_NATIVE_DIR/obj $PREFIX_NATIVE $PREFIX_BOLT $PREFIX_OPENSSL $OUTPUT $ROOT_NATIVE_DIR/obj/build-gmp $ROOT_NATIVE_DIR/obj/build-mpfr $ROOT_NATIVE_DIR/obj/build-isl $ROOT_NATIVE_DIR/obj/build-mpc $ROOT_NATIVE_DIR/obj/build-binutils $ROOT_NATIVE_DIR/obj/build-gcc-final $ROOT_NATIVE_DIR/obj/build-mathlib $ROOT_NATIVE_DIR/obj/build-jemalloc $ROOT_NATIVE_DIR/obj/build-autofdo $ROOT_NATIVE_DIR/obj/build-llvm-bolt $ROOT_NATIVE_DIR/obj/build-cmake $ROOT_NATIVE_DIR/obj/build-openssl

# Change libstdc++.so option.
sed -i "s#^\\t\$(OPT_LDFLAGS).*#\\t\$(OPT_LDFLAGS) \$(SECTION_LDFLAGS) \$(AM_CXXFLAGS) \$(LTLDFLAGS) -Wl,-z,relro,-z,now,-z,noexecstack -Wtrampolines -o \$\@#g" $ROOT_NATIVE_SRC/$GCC/libstdc++-v3/src/Makefile.in

echo "Building gmp..." && pushd $ROOT_NATIVE_DIR/obj/build-gmp
LDFLAGS="${SECURE_LDFLAGS}" CFLAGS="${SECURE_CFLAGS}" CXXFLAGS="${SECURE_CFLAGS}" $ROOT_NATIVE_SRC/$GMP/configure --prefix=$PREFIX_NATIVE --disable-shared --enable-cxx --build=$BUILD --host=$HOST
make -j $PARALLEL && make install && popd

echo "Building mpfr..." && pushd $ROOT_NATIVE_DIR/obj/build-mpfr
LDFLAGS="${SECURE_LDFLAGS}" CFLAGS="${SECURE_CFLAGS}" CXXFLAGS="${SECURE_CFLAGS}" $ROOT_NATIVE_SRC/$MPFR/configure --prefix=$PREFIX_NATIVE --disable-shared --with-gmp=$PREFIX_NATIVE --build=$BUILD --host=$HOST --target=$TARGET
make -j $PARALLEL && make install && popd

echo "Building isl..." && pushd $ROOT_NATIVE_DIR/obj/build-isl
LDFLAGS="${SECURE_LDFLAGS}" CFLAGS="${SECURE_CFLAGS}" CXXFLAGS="${SECURE_CFLAGS}" $ROOT_NATIVE_SRC/$ISL/configure --prefix=$PREFIX_NATIVE --with-gmp-prefix=$PREFIX_NATIVE --disable-shared --build=$BUILD --host=$HOST
make -j $PARALLEL && make install && popd

echo "Building mpc..." && pushd $ROOT_NATIVE_DIR/obj/build-mpc
LDFLAGS="${SECURE_LDFLAGS}" CFLAGS="${SECURE_CFLAGS}" CXXFLAGS="${SECURE_CFLAGS}" $ROOT_NATIVE_SRC/$MPC/configure --prefix=$PREFIX_NATIVE --disable-shared --with-gmp=$PREFIX_NATIVE --build=$BUILD --host=$HOST --target=$TARGET
make -j $PARALLEL && make install && popd

echo "Building binutils..." && pushd $ROOT_NATIVE_DIR/obj/build-binutils
LDFLAGS="${SECURE_LDFLAGS}" CFLAGS="${SECURE_CFLAGS}" CXXFLAGS="${SECURE_CFLAGS}" CFLAGS_FOR_TARGET="${SECURE_CFLAGS}" CXXFLAGS_FOR_TARGET="${SECURE_CFLAGS}" $ROOT_NATIVE_SRC/$BINUTILS/configure --prefix=$PREFIX_NATIVE --with-pkgversion="${COMPILER_INFO}" --enable-plugins --enable-ld=yes --libdir=$PREFIX_NATIVE/lib64 --enable-multiarch --build=$BUILD --host=$HOST --target=$TARGET
make -j $PARALLEL && make install prefix=$PREFIX_NATIVE exec_prefix=$PREFIX_NATIVE libdir=$PREFIX_NATIVE/lib64 && popd

# Temporarily install OpenSSL to provide fixed libcrypto.so version for various OSes.
echo "Building openssl for autofdo..." && pushd $ROOT_NATIVE_DIR/obj/build-openssl
cp -rf $ROOT_NATIVE_SRC/$OPENSSL/* .
LDFLAGS="${SECURE_LDFLAGS}" CFLAGS="${SECURE_CFLAGS}" CXXFLAGS="${SECURE_CFLAGS}" ./Configure --prefix=$PREFIX_OPENSSL --openssldir=$PREFIX_OPENSSL enable-ec_nistp_64_gcc_128 zlib enable-camellia enable-seed enable-rfc3779 enable-sctp enable-cms enable-md2 enable-rc5 enable-ssl3 enable-ssl3-method enable-weak-ssl-ciphers no-mdc2 no-ec2m enable-sm2 enable-sm3 enable-sm4 enable-tlcp shared linux-aarch64 -Wa,--noexecstack -DPURIFY '-DDEVRANDOM="\"/dev/urandom\""'
make -j $PARALLEL && make install && popd
export OPENSSL_ROOT_DIR=$PREFIX_OPENSSL
export PATH=$PREFIX_OPENSSL/bin:$PATH
export CPLUS_INCLUDE_PATH=$PREFIX_OPENSSL/include
export LIBRARY_PATH=$PREFIX_OPENSSL/lib
export LD_LIBRARY_PATH=$PREFIX_OPENSSL/lib
cp $PREFIX_OPENSSL/lib/libcrypto.so.1.1 $PREFIX_NATIVE/lib64

echo "Building autofdo..." && pushd $ROOT_NATIVE_DIR/obj/build-autofdo
cp -rf $ROOT_NATIVE_SRC/$AUTOFDO/* . && libtoolize && aclocal -I . && autoheader && autoconf && automake --add-missing -c
LDFLAGS="${SECURE_LDFLAGS}" CFLAGS="${SECURE_CFLAGS}" CXXFLAGS="${SECURE_CFLAGS}" ./configure --prefix=$PREFIX_NATIVE --build=$BUILD --host=$HOST
# AutoFDO doesn't support make parallel.
make -j 1 && make install && popd

# Temporarily install high version cmake required by bolt.
echo "Building cmake for bolt..." && pushd $ROOT_NATIVE_DIR/obj/build-cmake
$ROOT_NATIVE_SRC/$CMAKE/configure --prefix=$PREFIX_BOLT
make -j $PARALLEL && make install && popd
export PATH=$PREFIX_BOLT/bin:$PATH

echo "Building bolt..." && pushd $ROOT_NATIVE_DIR/obj/build-llvm-bolt
cmake -G"Unix Makefiles" $ROOT_NATIVE_SRC/$BOLT/llvm -DCMAKE_BUILD_TYPE=Release -DLLVM_ENABLE_ASSERTIONS=ON -DLLVM_ENABLE_PROJECTS="clang;lld;bolt" -DLLVM_TARGETS_TO_BUILD="AArch64" -DCMAKE_INSTALL_PREFIX=$PREFIX_BOLT
make -j $PARALLEL && make install && popd
# Put in llvm-bolt and perf2bolt.
cp $PREFIX_BOLT/bin/llvm-bolt $PREFIX_BOLT/bin/perf2bolt $PREFIX_NATIVE/bin

echo "Building GCC final..." && pushd $ROOT_NATIVE_DIR/obj/build-gcc-final
LDFLAGS="${SECURE_LDFLAGS}" CFLAGS="${SECURE_CFLAGS}" CXXFLAGS="${SECURE_CFLAGS}" CFLAGS_FOR_TARGET="${SECURE_CFLAGS}" CXXFLAGS_FOR_TARGET="${SECURE_CFLAGS}" $ROOT_NATIVE_SRC/$GCC/configure --prefix=$PREFIX_NATIVE --enable-shared --enable-threads=posix --enable-checking=release --enable-__cxa_atexit --enable-gnu-unique-object --enable-linker-build-id --with-linker-hash-style=gnu --enable-languages=c,c++,fortran,lto --enable-initfini-array --enable-gnu-indirect-function --with-multilib-list=lp64 --enable-multiarch --with-gnu-as --with-gnu-ld --enable-libquadmath --with-pkgversion="${COMPILER_INFO}" --with-sysroot=/ --with-gmp=$PREFIX_NATIVE --with-mpfr=$PREFIX_NATIVE --with-mpc=$PREFIX_NATIVE --with-isl=$PREFIX_NATIVE --libdir=$PREFIX_NATIVE/lib64 --disable-bootstrap --build=$BUILD --host=$HOST --target=$TARGET --enable-bolt
make -j $PARALLEL && make install prefix=$PREFIX_NATIVE exec_prefix=$PREFIX_NATIVE libdir=$PREFIX_NATIVE/lib64 && popd
