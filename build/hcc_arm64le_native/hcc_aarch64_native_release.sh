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
readonly PREFIX_PUBLIC="$PWD/arm64le_build_dir/$INSTALL_NATIVE/lib64_public"
readonly PREFIX_TEXINFO="$PWD/arm64le_build_dir/texinfo"
readonly PREFIX_BOLT="$PWD/arm64le_build_dir/llvm-bolt"
readonly PREFIX_OPENSSL="$PWD/arm64le_build_dir/openssl"
readonly PREFIX_MLIR="$PWD/arm64le_build_dir/llvm-mlir"
readonly PREFIX_PERL="$PWD/arm64le_build_dir/perl"
readonly PREFIX_ONNXRUNTIME="$PWD/arm64le_build_dir/onnxruntime"
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

create_directory $ROOT_NATIVE_DIR/obj $PREFIX_NATIVE $PREFIX_PUBLIC $PREFIX_PUBLIC/AI4C $PREFIX_TEXINFO $PREFIX_BOLT $PREFIX_OPENSSL $PREFIX_MLIR $PREFIX_PERL $PREFIX_ONNXRUNTIME $OUTPUT $ROOT_NATIVE_DIR/obj/build-gmp $ROOT_NATIVE_DIR/obj/build-mpfr $ROOT_NATIVE_DIR/obj/build-isl $ROOT_NATIVE_DIR/obj/build-texinfo $ROOT_NATIVE_DIR/obj/build-mpc $ROOT_NATIVE_DIR/obj/build-binutils $ROOT_NATIVE_DIR/obj/build-gcc-final $ROOT_NATIVE_DIR/obj/build-mathlib $ROOT_NATIVE_DIR/obj/build-jemalloc $ROOT_NATIVE_DIR/obj/build-autofdo $ROOT_NATIVE_DIR/obj/build-llvm-bolt $ROOT_NATIVE_DIR/obj/build-openssl $ROOT_NATIVE_DIR/obj/build-llvm-mlir $ROOT_NATIVE_DIR/obj/build-jsoncpp $ROOT_NATIVE_DIR/obj/build-grpc $ROOT_NATIVE_DIR/obj/build-protobuf $ROOT_NATIVE_DIR/obj/build-client $ROOT_NATIVE_DIR/obj/build-protobuf $ROOT_NATIVE_DIR/obj/build-ncurses $ROOT_NATIVE_DIR/obj/build-IPC-Cmd $ROOT_NATIVE_DIR/obj/build-cmake $ROOT_NATIVE_DIR/obj/build-yaml-cpp $ROOT_NATIVE_DIR/obj/build-AI4C

echo "Building gmp..." && pushd $ROOT_NATIVE_DIR/obj/build-gmp
LDFLAGS="${SECURE_LDFLAGS}" CFLAGS="${SECURE_CFLAGS}" CXXFLAGS="${SECURE_CFLAGS}" $ROOT_NATIVE_SRC/$GMP/configure --prefix=$PREFIX_NATIVE --disable-shared --enable-cxx --build=$BUILD --host=$HOST
make -j $PARALLEL && make install -j $PARALLEL && popd

echo "Building mpfr..." && pushd $ROOT_NATIVE_DIR/obj/build-mpfr
LDFLAGS="${SECURE_LDFLAGS}" CFLAGS="${SECURE_CFLAGS}" CXXFLAGS="${SECURE_CFLAGS}" $ROOT_NATIVE_SRC/$MPFR/configure --prefix=$PREFIX_NATIVE --disable-shared --with-gmp=$PREFIX_NATIVE --build=$BUILD --host=$HOST --target=$TARGET
make -j $PARALLEL && make install -j $PARALLEL && popd

echo "Building isl..." && pushd $ROOT_NATIVE_DIR/obj/build-isl
LDFLAGS="${SECURE_LDFLAGS}" CFLAGS="${SECURE_CFLAGS}" CXXFLAGS="${SECURE_CFLAGS}" $ROOT_NATIVE_SRC/$ISL/configure --prefix=$PREFIX_NATIVE --with-gmp-prefix=$PREFIX_NATIVE --disable-shared --build=$BUILD --host=$HOST
make -j $PARALLEL && make install -j $PARALLEL && popd

# Temporarily install high version texinfo required by mpc.
echo "Building texinfo for mpc..." && pushd $ROOT_NATIVE_DIR/obj/build-texinfo
$ROOT_NATIVE_SRC/$TEXINFO/configure --prefix=$PREFIX_TEXINFO --with-external-Text-Unidecode --with-external-libintl-perl --disable-perl-xs
make -j $PARALLEL && make install && popd
export PATH=$PREFIX_TEXINFO/bin:$PATH

echo "Building mpc..." && pushd $ROOT_NATIVE_DIR/obj/build-mpc
LDFLAGS="${SECURE_LDFLAGS}" CFLAGS="${SECURE_CFLAGS}" CXXFLAGS="${SECURE_CFLAGS}" $ROOT_NATIVE_SRC/$MPC/configure --prefix=$PREFIX_NATIVE --disable-shared --with-gmp=$PREFIX_NATIVE --build=$BUILD --host=$HOST --target=$TARGET
make -j $PARALLEL && make install -j $PARALLEL && popd

# Unset the temporary texinfo.
export PATH="${PATH#*:}"

echo "Building perl..." && pushd $ROOT_NATIVE_SRC/$PERL
LDFLAGS="${SECURE_LDFLAGS}" CFLAGS="${SECURE_CFLAGS}" CXXFLAGS="${SECURE_CFLAGS}" ./Configure -Dprefix=$PREFIX_PERL -des -Duseshrplib
make -j $PARALLEL && make install -j $PARALLEL && popd
export PATH=$PREFIX_PERL/bin:$PATH

echo "Building ncurses..." && pushd $ROOT_NATIVE_DIR/obj/build-ncurses
LDFLAGS="${SECURE_LDFLAGS}" CFLAGS="${SECURE_CFLAGS}" CXXFLAGS="${SECURE_CFLAGS}" $ROOT_NATIVE_SRC/$NCURSES/configure --prefix=$PREFIX_NATIVE --with-shared --build=$BUILD --host=$HOST --libdir=$PREFIX_PUBLIC

echo "Building binutils..." && pushd $ROOT_NATIVE_DIR/obj/build-binutils
LDFLAGS="${SECURE_LDFLAGS}" CFLAGS="${SECURE_CFLAGS}" CXXFLAGS="${SECURE_CFLAGS}" CFLAGS_FOR_TARGET="${SECURE_CFLAGS}" CXXFLAGS_FOR_TARGET="${SECURE_CFLAGS}" $ROOT_NATIVE_SRC/$BINUTILS/configure --prefix=$PREFIX_NATIVE --with-pkgversion="${COMPILER_INFO}" --enable-plugins --enable-ld=yes --libdir=$PREFIX_NATIVE/lib64 --enable-multiarch --build=$BUILD --host=$HOST --target=$TARGET
make -j $PARALLEL && make install -j $PARALLEL && popd

echo "Building perl-IPC-Cmd for OpenSSL..." && pushd $ROOT_NATIVE_SRC/$PERL_IPC_CMD
perl  Makefile.PL INSTALLDIRS=vendor NO_PACKLIST=1
make pure_install DESTDIR=$PREFIX_PERL && make install -j $PARALLEL && popd

# Temporarily install OpenSSL to provide fixed libcrypto.so version for various OSes.
echo "Building openssl for autofdo..." && pushd $ROOT_NATIVE_DIR/obj/build-openssl
cp -rf $ROOT_NATIVE_SRC/$OPENSSL/* .
LDFLAGS="${SECURE_LDFLAGS}" CFLAGS="${SECURE_CFLAGS}" CXXFLAGS="${SECURE_CFLAGS}" ./Configure --prefix=$PREFIX_OPENSSL --openssldir=$PREFIX_OPENSSL enable-ec_nistp_64_gcc_128 zlib enable-camellia enable-seed enable-rfc3779 enable-cms enable-md2 enable-rc5 no-mdc2 no-ec2m enable-sm2 enable-sm4 shared linux-aarch64 -Wa,--noexecstack -DPURIFY '-DDEVRANDOM="\"/dev/urandom\""'
make -j $PARALLEL && make install -j $PARALLEL && popd
export OPENSSL_ROOT_DIR=$PREFIX_OPENSSL
export PATH=$PREFIX_OPENSSL/bin:$PATH
export LIBRARY_PATH=$PREFIX_OPENSSL/lib64
export LD_LIBRARY_PATH=$PREFIX_OPENSSL/lib64
cp -r $PREFIX_OPENSSL/include/* $PREFIX_NATIVE/include
cp $PREFIX_OPENSSL/lib64/libssl.so.* $PREFIX_PUBLIC
cp $PREFIX_OPENSSL/lib64/libcrypto.so.* $PREFIX_PUBLIC
pushd $PREFIX_PUBLIC
ln -s libcrypto.so.3 libcrypto.so # AI4C
popd  

echo "Building cmake for bolt..." && pushd $ROOT_NATIVE_DIR/obj/build-cmake
LDFLAGS="${SECURE_LDFLAGS}" CFLAGS="${SECURE_CFLAGS}" CXXFLAGS="${SECURE_CFLAGS}" $ROOT_NATIVE_SRC/$CMAKE/configure --prefix=$PREFIX_BOLT
make -j $PARALLEL && make install -j $PARALLEL && popd
export PATH=$PREFIX_BOLT/bin:$PATH
export PATH=$PREFIX_NATIVE/bin:$PATH

echo "Building protobuf..." && pushd $ROOT_NATIVE_DIR/obj/build-protobuf
cmake $ROOT_NATIVE_SRC/$PROTOBUF -Dprotobuf_ABSL_PROVIDER=module -Dprotobuf_BUILD_TESTS=OFF -DCMAKE_SKIP_RPATH=TRUE -Dprotobuf_BUILD_LIBPROTOC:BOOL=ON -Dprotobuf_BUILD_SHARED_LIBS:BOOL=ON -DCMAKE_INSTALL_PREFIX=$PREFIX_NATIVE
make -j $PARALLEL && make install -j $PARALLEL && popd

export PATH=$PREFIX_NATIVE/bin:$PATH
export CPLUS_INCLUDE_PATH=$PREFIX_NATIVE/include
export LD_LIBRARY_PATH=$PREFIX_NATIVE/lib:$LD_LIBRARY_PATH
export PKG_CONFIG_PATH=$PREFIX_NATIVE/lib/pkgconfig

echo "Building autofdo..." && pushd $ROOT_NATIVE_DIR/obj/build-autofdo
cmake -G"Unix Makefiles" $ROOT_NATIVE_SRC/$AUTOFDO -DCMAKE_INSTALL_PREFIX=$PREFIX_NATIVE -DCMAKE_BUILD_TYPE=RelWithDebInfo -DENABLE_TOOL=GCOV -DCMAKE_LIBRARY_PATH=$PREFIX_OPENSSL/lib64
make -j $PARALLEL && make install -j $PARALLEL && popd
cp $ROOT_NATIVE_DIR/obj/build-autofdo/create_gcov $PREFIX_NATIVE/bin
cp $ROOT_NATIVE_DIR/obj/build-autofdo/dump_gcov $PREFIX_NATIVE/bin
cp $ROOT_NATIVE_DIR/obj/build-autofdo/profile_merger $PREFIX_NATIVE/bin

echo "Building bolt..." && pushd $ROOT_NATIVE_DIR/obj/build-llvm-bolt
cmake -G"Unix Makefiles" $ROOT_NATIVE_SRC/$BOLT/llvm -DCMAKE_BUILD_TYPE=Release -DLLVM_ENABLE_ASSERTIONS=ON -DLLVM_ENABLE_PROJECTS="bolt" -DLLVM_TARGETS_TO_BUILD="AArch64" -DCMAKE_INSTALL_PREFIX=$PREFIX_BOLT -DBUILD_SHARED_LIBS:BOOL=OFF
make -j $PARALLEL && make install -j $PARALLEL && popd
# Put in llvm-bolt and perf2bolt.
cp $PREFIX_BOLT/bin/llvm-bolt $PREFIX_BOLT/bin/perf2bolt $PREFIX_BOLT/bin/merge-fdata $PREFIX_NATIVE/bin
cp -r $PREFIX_BOLT/lib/lib* $PREFIX_NATIVE/lib

echo "Building mlir..." && pushd $ROOT_NATIVE_DIR/obj/build-llvm-mlir
cmake -G"Unix Makefiles" $ROOT_NATIVE_SRC/$MLIR -DLLVM_ENABLE_RTTI=ON -DCMAKE_BUILD_TYPE=Release -DLLVM_ENABLE_ASSERTIONS=ON -DLLVM_ENABLE_PROJECTS="mlir" -DLLVM_TARGETS_TO_BUILD="AArch64" -DCMAKE_INSTALL_PREFIX=$PREFIX_MLIR
make -j $PARALLEL && make install -j $PARALLEL && popd 

export PATH=$ROOT_NATIVE_DIR/obj/build-llvm-mlir/bin:$PATH
cp $ROOT_NATIVE_DIR/obj/build-llvm-mlir/bin/mlir-tblgen /usr/bin
cp -r $PREFIX_MLIR/lib/* $PREFIX_PUBLIC
cp -r $PREFIX_MLIR/include/* $PREFIX_NATIVE/include

echo "Building grpc..." && pushd $ROOT_NATIVE_SRC/$GRPC
# avoid downloading
mkdir  $ROOT_NATIVE_SRC/$GRPC/third_party/opencensus-proto/src
sed -r -i 's/(std=c\+\+)14/\1%{cpp_std}/g' setup.py grpc.gyp Rakefile examples/cpp/*/Makefile examples/cpp/*/CMakeLists.txt tools/run_tests/artifacts/artifact_targets.py tools/distrib/python/grpcio_tools/setup.py && popd
pushd $ROOT_NATIVE_DIR/obj/build-grpc
cmake -G "Unix Makefiles" $ROOT_NATIVE_SRC/$GRPC -DCMAKE_BUILD_TYPE=Release -DgRPC_INSTALL=ON -DgRPC_CARES_PROVIDER=module -DgRPC_PROTOBUF_PROVIDER=package -DgRPC_SSL_PROVIDER=package -DgRPC_RE2_PROVIDER=module -DgRPC_ABSL_PROVIDER=package -DCMAKE_INSTALL_PREFIX=$PREFIX_NATIVE -DgRPC_INSTALL_LIBDIR=$PREFIX_PUBLIC -DProtobuf_INCLUDE_DIR=$PREFIX_NATIVE/include -DProtobuf_LIBRARY=$PREFIX_NATIVE/lib/libprotobuf.so -DProtobuf_PROTOC_LIBRARY=$PREFIX_NATIVE/lib/libprotoc.so -DProtobuf_PROTOC_EXECUTABLE=$PREFIX_NATIVE/bin/protoc -DBUILD_DEPS=ON -DBUILD_SHARED_LIBS=ON -DCMAKE_C_FLAGS="${SECURE_CFLAGS}" -DCMAKE_CXX_FLAGS="${SECURE_CFLAGS}" -DCMAKE_SHRAED_LINKER_FLAGS="${SECURE_LDFLAGS}"
make -j $PARALLEL && make install -j $PARALLEL && popd

echo "Building jsoncpp..." && pushd $ROOT_NATIVE_DIR/obj/build-jsoncpp
cmake -G"Unix Makefiles" $ROOT_NATIVE_SRC/$JSONCPP -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX=$PREFIX_NATIVE -DCMAKE_INSTALL_LIBDIR=$PREFIX_PUBLIC -DCMAKE_C_FLAGS="${SECURE_CFLAGS}" -DCMAKE_CXX_FLAGS="${SECURE_CFLAGS}" -DCMAKE_SHRAED_LINKER_FLAGS="${SECURE_LDFLAGS}"
make -j $PARALLEL && make install -j $PARALLEL && popd

echo "Building GCC final..." && pushd $ROOT_NATIVE_DIR/obj/build-gcc-final
LDFLAGS="${SECURE_LDFLAGS} -ldl" CFLAGS="${SECURE_CFLAGS}" CXXFLAGS="${SECURE_CFLAGS}" CFLAGS_FOR_TARGET="${SECURE_CFLAGS}" CXXFLAGS_FOR_TARGET="${SECURE_CFLAGS}" $ROOT_NATIVE_SRC/$GCC/configure --prefix=$PREFIX_NATIVE --enable-shared --enable-threads=posix --enable-checking=release --enable-__cxa_atexit --enable-gnu-unique-object --enable-linker-build-id --with-linker-hash-style=gnu --enable-languages=c,c++,fortran,lto --enable-initfini-array --enable-gnu-indirect-function --with-multilib-list=lp64 --enable-multiarch --with-gnu-as --with-gnu-ld --enable-libquadmath --with-pkgversion="${COMPILER_INFO}" --with-sysroot=/ --with-gmp=$PREFIX_NATIVE --with-mpfr=$PREFIX_NATIVE --with-mpc=$PREFIX_NATIVE --with-isl=$PREFIX_NATIVE --libdir=$PREFIX_NATIVE/lib64 --disable-bootstrap --build=$BUILD --host=$HOST --target=$TARGET --enable-bolt
make -j $PARALLEL && make install -j $PARALLEL && popd
