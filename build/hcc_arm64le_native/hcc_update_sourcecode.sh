#!/bin/bash
# This file is provided as a guideline for users who wish
# to fix random difference in binutils and gcc. And
# avoid repeatedly generate the document files and
# makefile* files.
# Copyright (c) Huawei Technologies Co., Ltd. 2023-2023. All rights reserved.

set -e

readonly ROOT_NATIVE_SRC="$PWD/../../open_source/hcc_arm64le_native_build_src"

if [[ -z "$COMPILER_INFO" ]]; then
    source $PWD/../config.xml
fi

find $ROOT_NATIVE_SRC/$BINUTILS -name "*.c" | xargs -i bash -c "touch {}"
find $ROOT_NATIVE_SRC/$BINUTILS -name "*.info" | xargs -i bash -c "touch {}"
touch $ROOT_NATIVE_SRC/$BINUTILS/binutils/doc/binutils.texi
find $ROOT_NATIVE_SRC/$BINUTILS -name "*.1" | xargs -i bash -c "touch {}"

# Touch iterators.md to avoid not found aarch64-builtin-iterators.h.
touch $ROOT_NATIVE_SRC/$GCC/gcc/config/aarch64/iterators.md

find $ROOT_NATIVE_SRC/$GCC -name "*.c" | xargs -i bash -c "touch {}"
find $ROOT_NATIVE_SRC/$GCC -name "*.1" | xargs -i bash -c "touch {}"
find $ROOT_NATIVE_SRC/$GCC -name "*.info" | xargs -i bash -c "touch {}"

# Avoid generate Makefile.am.
touch $ROOT_NATIVE_SRC/$MPFR/*.m4
touch $ROOT_NATIVE_SRC/$MPFR/configure
touch $ROOT_NATIVE_SRC/$MPFR/Makefile.*
touch $ROOT_NATIVE_SRC/$ISL/*.m4
touch $ROOT_NATIVE_SRC/$ISL/configure
touch $ROOT_NATIVE_SRC/$ISL/Makefile.*
