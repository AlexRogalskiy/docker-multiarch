#!/bin/bash
set -ex

# NOTE: this url will change regularly because it's unstable
PACKAGE=http://ftp.us.debian.org/debian/pool/main/q/qemu/$(lynx -listonly -nonumbers -dump http://ftp.us.debian.org/debian/pool/main/q/qemu/ | grep -o qemu-user-static_.*_amd64.deb | sed "s/%2B/+/g " | tail -n 1)

mkdir tmp/
cd tmp/

curl $PACKAGE -o $(basename ${PACKAGE})
dpkg-deb -X $(basename ${PACKAGE}) .
cp usr/bin/qemu-aarch64-static ..
cp usr/bin/qemu-arm-static ..
cp usr/bin/qemu-ppc64le-static ..
cd ..
rm -rf tmp
