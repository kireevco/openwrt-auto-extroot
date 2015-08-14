#!/bin/bash

set -e

absolutize ()
{
  if [ ! -d "$1" ]; then
    echo
    echo "ERROR: '$1' doesn't exist or not a directory!"
    kill -INT $$
  fi

  pushd "$1" >/dev/null
  echo `pwd`
  popd >/dev/null
}

TARGET_PLATFORM=$1

if [ -z ${TARGET_PLATFORM} ]; then
    echo "Usage: $0 target-platform (e.g. 'TLWDR4300')"
    kill -INT $$
fi

BUILD=`dirname "$0"`"/build/"
BUILD=`absolutize $BUILD`
IMGTEMPDIR="${BUILD}/openwrt-build-image-extras"
IMGBUILDERDIR="${BUILD}/OpenWrt-ImageBuilder-ar71xx_generic-for-linux-x86_64"
IMGBUILDERURL="http://ec2-52-26-170-245.us-west-2.compute.amazonaws.com/ar71xx/OpenWrt-ImageBuilder-ar71xx_generic-for-linux-x86_64.tar.bz2"

PREINSTALLED_PACKAGES="wireless-tools firewall iptables"
PREINSTALLED_PACKAGES+=" ppp ppp-mod-pppoe ppp-mod-pppol2tp ppp-mod-pptp kmod-ppp kmod-pppoe"
PREINSTALLED_PACKAGES+=" fdisk blkid swap-utils mount-utils block-mount e2fsprogs kmod-fs-ext4 kmod-usb2 kmod-usb-uhci kmod-usb-ohci kmod-usb-storage kmod-usb-storage-extras kmod-mmc"
PREINSTALLED_PACKAGES+=" wget coreutils-chroot"

mkdir --parents ${BUILD}

rm -rf $IMGTEMPDIR
cp -r image-extras/common $IMGTEMPDIR
PER_PLATFORM_IMAGE_EXTRAS=image-extras/${TARGET_PLATFORM}/
if [ -e $PER_PLATFORM_IMAGE_EXTRAS ]; then
    rsync -pr $PER_PLATFORM_IMAGE_EXTRAS $IMGTEMPDIR/
fi

if [ ! -e ${IMGBUILDERDIR} ]; then
    pushd ${BUILD}
    wget --continue ${IMGBUILDERURL}
    tar jvxf OpenWrt-ImageBuilder*.tar.bz2 
    printf "src/gz barrier_breaker_base http://downloads.openwrt.org/barrier_breaker/14.07/ar71xx/generic/packages/base
src/gz barrier_breaker_luci http://downloads.openwrt.org/barrier_breaker/14.07/ar71xx/generic/packages/luci
src/gz barrier_breaker_management http://downloads.openwrt.org/barrier_breaker/14.07/ar71xx/generic/packages/management
src/gz barrier_breaker_oldpackages http://downloads.openwrt.org/barrier_breaker/14.07/ar71xx/generic/packages/oldpackages
src/gz barrier_breaker_packages http://downloads.openwrt.org/barrier_breaker/14.07/ar71xx/generic/packages/packages
src/gz barrier_breaker_routing http://downloads.openwrt.org/barrier_breaker/14.07/ar71xx/generic/packages/routing
src/gz barrier_breaker_telephony http://downloads.openwrt.org/barrier_breaker/14.07/ar71xx/generic/packages/telephony" >> $IMGBUILDERDIR/repositories.conf
    popd
fi

pushd ${IMGBUILDERDIR}

make image PROFILE=${TARGET_PLATFORM} PACKAGES="${PREINSTALLED_PACKAGES}" FILES=${IMGTEMPDIR}

pushd bin/ar71xx/
ln -s ../../packages .
popd

popd
