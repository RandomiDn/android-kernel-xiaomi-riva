#!/usr/bin/env bash

set -e

function message() {
    echo -e "\e[1;32m$*\e[0m"
}

ROOT=$(pwd)
ZIPNAME=Nbr-kernel-4.9-riva-$(date +"%F")
MAKE_FLAGS=(
    CROSS_COMPILE=aarch64-elf-
    CROSS_COMPILE_ARM32=arm-eabi-
)
JOBS=$(nproc --all)

export PATH=$ROOT/arm64-gcc/bin:$ROOT/arm-gcc/bin:$PATH
export KBUILD_BUILD_USER=mamles
export KBUILD_BUILD_HOST=drone

function clone() {
    message "Cloning dependencies..."
    if ! [ -a AnyKernel3 ]; then
        git clone --depth=1 https://github.com/nbr-project/AnyKernel3 -b riva AnyKernel3
    fi
    if ! [ -a arm64-gcc ]; then
        git clone --depth=1 https://github.com/nbr-project/arm64-gcc -b master arm64-gcc
    fi
    if ! [ -a arm-gcc ]; then
        git clone --depth=1 https://github.com/nbr-project/arm-gcc -b master arm-gcc
    fi
}

function compile() {
    message "Compiling kernel..."
    if [ -a out ]; then
        rm -rf out
    fi
    make O=out ARCH=arm64 riva_defconfig -j"$JOBS" \
        "${MAKE_FLAGS[@]}"
    make O=out ARCH=arm64 -j"$JOBS" \
        "${MAKE_FLAGS[@]}"
}

function repack() {
    message "Repacking kernel..."
    if ! [ -a AnyKernel3/Image.gz-dtb ]; then
        cp out/arch/arm64/boot/Image.gz-dtb AnyKernel3
    fi
    cd AnyKernel3
    if [ -a "${ZIPNAME}".zip ]; then
        rm -rf "${ZIPNAME}".zip
    fi
    zip -r9 "${ZIPNAME}".zip ./* -x .git README.md ./*placeholder zipsigner-3.0.jar
    if [ -a Image.gz-dtb ]; then
        rm -rf Image.gz-dtb
    fi
    if [ -a "${ZIPNAME}"-signed.zip ]; then
        rm -rf "${ZIPNAME}"-signed.zip
    fi
    java -jar zipsigner-3.0.jar "${ZIPNAME}".zip "${ZIPNAME}"-signed.zip
    cd "$ROOT"
}

clone
compile
repack
