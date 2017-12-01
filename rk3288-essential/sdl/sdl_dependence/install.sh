#!/bin/bash

if [ -d "lib" ]; then
    rm -rf lib
fi

if [ -d "usr" ]; then
    rm -rf usr
fi

echo "-- Extract libbluetooth ..."
dpkg-deb -x packages/libbluetooth3_*-*_armhf.deb .
dpkg-deb -x packages/libbluetooth-dev_*-*_armhf.deb .

echo "-- Extract libssl ..."
dpkg-deb -x packages/libssl1.0.0_*-*_armhf.deb .
dpkg-deb -x packages/libssl-dev_*-*_armhf.deb .

echo "-- Extract libsqlite3 ..."
dpkg-deb -x packages/libsqlite3-0_*-*_armhf.deb .
dpkg-deb -x packages/libsqlite3-dev_*-*_armhf.deb .

echo "-- Extract libudev ..."
dpkg-deb -x packages/libudev1_*-*_armhf.deb .
dpkg-deb -x packages/libudev-dev_*-*_armhf.deb .

echo "-- Extract libapr ..."
dpkg-deb -x packages/libapr1_*_armhf.deb .
dpkg-deb -x packages/libapr1-dev_*_armhf.deb .

echo "-- Extract libaprutil ..."
dpkg-deb -x packages/libaprutil1_*-1build1_armhf.deb .
dpkg-deb -x packages/libaprutil1-dev_*-1build1_armhf.deb .

echo "-- Extract liblog4cxx ..."
dpkg-deb -x packages/liblog4cxx10v5_*-10ubuntu1_armhf.deb .
dpkg-deb -x packages/liblog4cxx-dev_*-*_armhf.deb .

echo "-- Extract libplist ..."
dpkg-deb -x packages/libplist3_*-*_armhf.deb .
dpkg-deb -x packages/libplist-dev_*-*_armhf.deb .

echo "-- Extract libusbmuxd ..."
dpkg-deb -x packages/libusbmuxd4_*-2ubuntu0.1_armhf.deb .
dpkg-deb -x packages/libusbmuxd-dev_*-2ubuntu0.1_armhf.deb .

echo "-- Extract libxml2 ..."
dpkg-deb -x packages/libxml2_*+*_armhf.deb .
dpkg-deb -x packages/libxml2-dev_*+*_armhf.deb .

echo "-- Extract zlib1g ..."
dpkg-deb -x packages/zlib1g_*_armhf.deb .
dpkg-deb -x packages/zlib1g-dev_*_armhf.deb .

echo "-- Extract libicu ..."
dpkg-deb -x packages/libicu55_*-*_armhf.deb .
dpkg-deb -x packages/libicu-dev_*-*_armhf.deb .

echo "-- Extract liblzma ..."
dpkg-deb -x packages/liblzma5_*-*_armhf.deb .
dpkg-deb -x packages/liblzma-dev_*-*_armhf.deb .

echo "-- Do some work ..."
mv ./usr/include/arm-linux-gnueabihf/openssl/opensslconf.h ./usr/include/openssl/
rm -rf ./usr/include/arm-linux-gnueabihf
mv ./usr/lib/arm-linux-gnueabihf/* ./usr/lib
rm -rf ./usr/lib/arm-linux-gnueabihf
mkdir -p ./usr/arm-linux-gnueabihf
mv ./usr/bin ./usr/arm-linux-gnueabihf
mv ./usr/include ./usr/arm-linux-gnueabihf
mv ./usr/lib ./usr/arm-linux-gnueabihf
mv ./usr/share ./usr/arm-linux-gnueabihf

echo "-- Install to system ..."
cp -rf ./lib/* /lib
cp -rf ./usr/arm-linux-gnueabihf/* /usr/arm-linux-gnueabihf

find lib/ -name "*" > install_record.txt
find usr/ -name "*" >> install_record.txt

echo "-- Done."
