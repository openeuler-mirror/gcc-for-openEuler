#!/bin/bash
# This file contains the complete sequence of commands
# to build the toolchain, including the configuration
# options and compilation processes.
# Copyright (c) Huawei Technologies Co., Ltd. 2023-2023. All rights reserved.

set -e

# Environment variables that never change during the build process.
if [[ -z "$COMPILER_INFO" ]]; then
    source $PWD/../config.xml
fi

# Target root directory, should be adapted according to your environment.
readonly ROOT_NATIVE_DIR="$PWD/arm64le_build_dir"
readonly ROOT_NATIVE_SRC="$PWD/../../open_source/hcc_arm64le_native_build_src"
readonly PREFIX_NATIVE="$PWD/arm64le_build_dir/$INSTALL_NATIVE"
readonly PREFIX_GRPC="$PWD/arm64le_build_dir/grpc"
readonly PREFIX_BOLT="$PWD/arm64le_build_dir/llvm-bolt"
readonly PREFIX_OPENSSL="$PWD/arm64le_build_dir/openssl"
readonly PREFIX_PROTOBUF="$PWD/arm64le_build_dir/protobuf"
readonly PREFIX_MLIR="$PWD/arm64le_build_dir/llvm-mlir"
readonly PREFIX_JSONCPP="$PWD/arm64le_build_dir/jsoncpp"
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

create_directory $ROOT_NATIVE_DIR/obj $PREFIX_NATIVE $PREFIX_GRPC $PREFIX_BOLT $PREFIX_OPENSSL $PREFIX_PROTOBUF $PREFIX_MLIR $PREFIX_JSONCPP $OUTPUT $ROOT_NATIVE_DIR/obj/build-gmp $ROOT_NATIVE_DIR/obj/build-mpfr $ROOT_NATIVE_DIR/obj/build-isl $ROOT_NATIVE_DIR/obj/build-mpc $ROOT_NATIVE_DIR/obj/build-binutils $ROOT_NATIVE_DIR/obj/build-gcc-final $ROOT_NATIVE_DIR/obj/build-mathlib $ROOT_NATIVE_DIR/obj/build-jemalloc $ROOT_NATIVE_DIR/obj/build-autofdo $ROOT_NATIVE_DIR/obj/build-llvm-bolt $ROOT_NATIVE_DIR/obj/build-cmake $ROOT_NATIVE_DIR/obj/build-openssl $ROOT_NATIVE_DIR/obj/build-llvm-mlir ${ROOT_NATIVE_DIR}/obj/build-jsoncpp $ROOT_NATIVE_DIR/obj/build-grpc $ROOT_NATIVE_DIR/obj/build-protobuf $ROOT_NATIVE_DIR/obj/build-client $ROOT_NATIVE_DIR/obj/build-protobuf $ROOT_NATIVE_DIR/obj/build-ncurses

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

echo "Building ncurses..." && pushd $ROOT_NATIVE_DIR/obj/build-ncurses
LDFLAGS="${SECURE_LDFLAGS}" CFLAGS="${SECURE_CFLAGS}" CXXFLAGS="${SECURE_CFLAGS}" $ROOT_NATIVE_SRC/$NCURSES/configure --prefix=$PREFIX_NATIVE --with-shared --build=$BUILD --host=$HOST --libdir=$PREFIX_NATIVE/lib64
make -j $PARALLEL && make install prefix=$PREFIX_NATIVE exec_prefix=$PREFIX_NATIVE libdir=$PREFIX_NATIVE/lib64 && popd
ln -s $PREFIX_NATIVE/lib64/libncurses.so $PREFIX_NATIVE/lib64/libtinfo.so
ln -s $PREFIX_NATIVE/lib64/libncurses.so.6 $PREFIX_NATIVE/lib64/libtinfo.so.6
ln -s $PREFIX_NATIVE/lib64/libncurses.so.6.3 $PREFIX_NATIVE/lib64/libtinfo.so.6.3

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
cp $PREFIX_OPENSSL/lib/libssl.so.1.1 $PREFIX_NATIVE/lib64

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

echo "Building mlir..." && pushd $ROOT_NATIVE_DIR/obj/build-llvm-mlir
cmake -G"Unix Makefiles" $ROOT_NATIVE_SRC/$MLIR/llvm -DLLVM_ENABLE_RTTI=ON -DCMAKE_BUILD_TYPE=Release -DLLVM_ENABLE_ASSERTIONS=ON -DLLVM_ENABLE_PROJECTS="mlir" -DLLVM_TARGETS_TO_BUILD="AArch64" -DCMAKE_INSTALL_PREFIX=$PREFIX_MLIR
make -j $PARALLEL && make install && popd
export PATH=$PREFIX_MLIR/bin:$PATH
cp $PREFIX_MLIR/bin/mlir-tblgen /usr/bin
cp -r $PREFIX_MLIR/lib/* $PREFIX_NATIVE/lib64

echo "Building protobuf..." && pushd $ROOT_NATIVE_DIR/obj/build-protobuf
cp -rf $ROOT_NATIVE_SRC/$PROTOBUF/* .
sed -i '37{s/$/ -I \/usr\/share\/aclocal/}' autogen.sh && ./autogen.sh && ./configure --prefix=$PREFIX_PROTOBUF
make -j && make install && popd
cp -r $PREFIX_PROTOBUF/lib/* $PREFIX_NATIVE/lib64

export PATH=$PREFIX_PROTOBUF/bin:$PATH
export LD_LIBRARY_PATH=$PREFIX_PROTOBUF/lib:$LD_LIBRARY_PATH
export PKG_CONFIG_PATH=$PREFIX_PROTOBUF/lib/pkgconfig

echo "Building grpc..." && pushd "${ROOT_NATIVE_DIR}/obj/build-grpc"
cmake -G "Unix Makefiles" $ROOT_NATIVE_SRC/$GRPC -DCMAKE_BUILD_TYPE=Release -DgRPC_INSTALL=ON -DgRPC_CARES_PROVIDER=module -DgRPC_PROTOBUF_PROVIDER=package -DgRPC_SSL_PROVIDER=package -DgRPC_RE2_PROVIDER=module -DgRPC_ABSL_PROVIDER=module -DCMAKE_INSTALL_PREFIX=$ROOT_NATIVE_DIR/obj/build-grpc -DProtobuf_INCLUDE_DIR=$PREFIX_PROTOBUF/include -DProtobuf_LIBRARY=$PREFIX_PROTOBUF/lib/libprotobuf.so -DProtobuf_PROTOC_LIBRARY=$PREFIX_PROTOBUF/lib/libprotoc.so -DProtobuf_PROTOC_EXECUTABLE=$PREFIX_PROTOBUF/bin/protoc -DBUILD_DEPS=ON -DBUILD_SHARED_LIBS=ON -DCMAKE_INSTALL_PREFIX=$PREFIX_GRPC
make -j $PARALLEL && make install && popd
cp -r $PREFIX_GRPC/lib/* $PREFIX_NATIVE/lib64

echo "Building jsoncpp..." && pushd "${ROOT_NATIVE_DIR}/obj/build-jsoncpp"
cmake -G"Unix Makefiles" $ROOT_NATIVE_SRC/$JSONCPP -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX=$PREFIX_JSONCPP
make -j $PARALLEL && make install && popd
cp -r $PREFIX_JSONCPP/lib/* $PREFIX_NATIVE/lib64

echo "Building GCC final..." && pushd $ROOT_NATIVE_DIR/obj/build-gcc-final
LDFLAGS="${SECURE_LDFLAGS}" CFLAGS="${SECURE_CFLAGS}" CXXFLAGS="${SECURE_CFLAGS}" CFLAGS_FOR_TARGET="${SECURE_CFLAGS}" CXXFLAGS_FOR_TARGET="${SECURE_CFLAGS}" $ROOT_NATIVE_SRC/$GCC/configure --prefix=$PREFIX_NATIVE --enable-shared --enable-threads=posix --enable-checking=release --enable-__cxa_atexit --enable-gnu-unique-object --enable-linker-build-id --with-linker-hash-style=gnu --enable-languages=c,c++,fortran,lto --enable-initfini-array --enable-gnu-indirect-function --with-multilib-list=lp64 --enable-multiarch --with-gnu-as --with-gnu-ld --enable-libquadmath --with-pkgversion="${COMPILER_INFO}" --with-sysroot=/ --with-gmp=$PREFIX_NATIVE --with-mpfr=$PREFIX_NATIVE --with-mpc=$PREFIX_NATIVE --with-isl=$PREFIX_NATIVE --libdir=$PREFIX_NATIVE/lib64 --disable-bootstrap --build=$BUILD --host=$HOST --target=$TARGET --enable-bolt
make -j $PARALLEL && make install prefix=$PREFIX_NATIVE exec_prefix=$PREFIX_NATIVE libdir=$PREFIX_NATIVE/lib64 && popd
