#!/bin/sh
#
# Install musl and musl-sanitized linux kernel headers
# to musl-{$1} directory

set -eux

musl_version=1.1.24
musl="musl-${musl_version}"

# Download, configure, build, and install musl:
curl --retry 5 https://www.musl-libc.org/releases/${musl}.tar.gz | tar xzf -

cd "$musl"
case ${1} in
    aarch64)
        musl_arch=aarch64
        kernel_arch=arm64
        CC=aarch64-linux-gnu-gcc \
          ./configure --prefix="/musl-${musl_arch}" --enable-wrapper=yes
        make install -j4
        ;;
    arm)
        musl_arch=arm
        kernel_arch=arm
        CC=arm-linux-gnueabihf-gcc CFLAGS="-march=armv6 -marm -mfpu=vfp" \
          ./configure --prefix="/musl-${musl_arch}" --enable-wrapper=yes
        make install -j4
        ;;
    i686)
        # cross-compile musl for i686 using the system compiler on an x86_64
        # system.
        musl_arch=i686
        kernel_arch=i386
        # Specifically pass -m32 in CFLAGS and override CC when running
        # ./configure, since otherwise the script will fail to find a compiler.
        CC=gcc CFLAGS="-m32" \
          ./configure --prefix="/musl-${musl_arch}" --disable-shared --target=i686
        # unset CROSS_COMPILE when running make; otherwise the makefile will
        # call the non-existent binary 'i686-ar'.
        make CROSS_COMPILE= install -j4
        ;;
    x86_64)
        musl_arch=x86_64
        kernel_arch=x86_64
        ./configure --prefix="/musl-${musl_arch}"
        make install -j4
        ;;
    s390x)
        musl_arch=s390x
        kernel_arch=s390
        CC=s390x-linux-gnu-gcc \
          ./configure --prefix="/musl-${musl_arch}" --enable-wrapper=yes
        make install -j4
        ;;
    *)
        echo "Unknown target arch: \"${1}\""
        exit 1
        ;;
esac


# shellcheck disable=SC2103
cd ..
rm -rf "$musl"

# Download, configure, build, and install musl-sanitized kernel headers:
kernel_header_ver="4.19.88"
curl --retry 5 -L \
    "https://github.com/sabotage-linux/kernel-headers/archive/v${kernel_header_ver}.tar.gz" |
    tar xzf -
(
    cd "kernel-headers-${kernel_header_ver}"
    make ARCH="${kernel_arch}" prefix="/musl-${musl_arch}" install -j4
)
rm -rf kernel-headers-${kernel_header_ver}
