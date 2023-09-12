#!/bin/bash
# The entrance to build the compiler toolchain.
# Copyright (c) Huawei Technologies Co., Ltd. 2023-2023. All rights reserved.

set -e

readonly LOG_PATH="$PWD/logs"
readonly OPEN_SOURCE_PATH="$PWD/../open_source"

# Check if the build tool exists, build error when missing tools.
miss_tool_error() {
    $1 $2
    if [ $? -ne 0 ]; then
        echo "####################################################################"
        echo "#               ERROR: $1 is not found !!                        #"
        echo "####################################################################"
        exit 1
    else
        echo "$1 checked success!!"
    fi
}

# Clear history build legacy files.
# All build logs are placed in the logs directory.
# The intermediate file is placed in the directory name with the "_build_dir" keyword.
# The source code is placed in the directory name with the "_build_src" keyword.
clean() {
    for file in $(find $OPEN_SOURCE_PATH -name "*_build_src"); do
        [ -n "$file" ] && rm -rf $file
    done

    for file in $(find . -name "*_build_dir"); do
        [ -n "$file" ] && rm -rf $file
    done

    [ -n "$PWD/../output" ] && rm -rf $PWD/../output/*

    [ -n "$LOG_PATH" ] && rm -rf $LOG_PATH
}

if [[ $1 =~ ^hcc_arm64le_native(/)?$ ]]; then
    cd $1
elif [ "$1"x = "clean"x ]; then
    clean
    exit 0
else
    echo 'Using "sh build.sh xxx" to build the toolchain, xxx is the toolchain name.'
    echo 'Using "sh build.sh clean" to clear history build legacy files.'
    exit 0
fi

echo "$(date +"%Y-%m-%d %H:%M:%S") ======== begin building ========"
source ../config.xml
miss_tool_error gcc -v
miss_tool_error g++ -v
miss_tool_error bison --version
miss_tool_error flex --version
miss_tool_error makeinfo --version

bash build.sh
exit 0
