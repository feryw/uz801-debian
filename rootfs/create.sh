#!/bin/bash
set -e

# === Configuration ===
DIST=bookworm
UUID=62ae670d-01b7-4c7d-8e72-60bcd00410b7
ROOTFS=debian
BUILD=build
KERNEL_DIR=../kernel

BOOT_URL="https://github.com/feryw/msm8916-kernel/releases/download/v6.12.1-armv7/boot-armv7.img"
K_IMAGE_DEB_URL="https://github.com/feryw/msm8916-kernel/releases/download/v6.12.1-armv7/linux-image-6.12.1-wyref_6.12.1-gadb539838e7e-1_armhf.deb"
K_HEADER_DEB_URL="https://github.com/feryw/msm8916-kernel/releases/download/v6.12.1-armv7/linux-headers-6.12.1-wyref_6.12.1-gadb539838e7e-1_armhf.deb"
K_DEV_URL="https://github.com/feryw/msm8916-kernel/releases/tag/v6.12.1-armv7"

# === Root check ===
if [ "$(id -u)" -ne 0 ]; then
  echo "Please run as root"
  exit 1
fi

# === Prepare directories ===
mkdir -p "$KERNEL_DIR" "$ROOTFS" "$BUILD"

# === Download kernel artifacts ===
wget -P "$KERNEL_DIR" "$BOOT_URL"
wget -P "$KERNEL_DIR" "$K_IMAGE_DEB_URL"
wget -P "$KERNEL_DIR" "$K_HEADER_DEB_URL"

# === Bootstrap rootfs ===
debootstrap --arch=armhf --foreign "$DIST" "$ROOTFS" https://deb.debian.org/debian/
LANG=C LANGUAGE=C LC_ALL=C chroot "$ROOTFS" /debootstrap/debootstrap --second-stage

# === Fix DNS inside chroot ===
mkdir -p "$ROOTFS/etc"
rm -f "$ROOTFS/etc/resolv.conf"
echo "nameserver 8.8.8.8" > "$ROOTFS/etc/resolv.conf"

# === Copy kernel .deb and chroot script ===
cp "$KERNEL_DIR"/linux-*.deb "$ROOTFS/tmp/"
cp chroot.sh "$ROOTFS/tmp/"

# === Mount system directories ===
for dir in proc sys dev dev/pts; do
  mount --bind "/$dir" "$ROOTFS/$dir"
done

# === Enter chroot ===
LANG=C LANGUAGE=C LC_ALL=C chroot "$ROOTFS" /bin/bash /tmp/chroot.sh

# === Unmount cleanly ===
for dir in dev/pts dev sys proc; do
  umount "$ROOTFS/$dir"
done

# === Finalize image ===
dd if=/dev/zero of=debian-uz801v3.img bs=1M count=$(( $(du -ms "$ROOTFS" | cut -f1) + 100 ))
mkfs.ext4 -L rootfs -U "$UUID" debian-uz801v3.img
mount debian-uz801v3.img "$BUILD"
rsync -aH "$ROOTFS/" "$BUILD/"
umount "$BUILD"
img2simg debian-uz801v3.img rootfs.img

# === Metadata ===
cp "$ROOTFS/etc/debian_version" ./
echo > info.md
echo '## Enable Modem
