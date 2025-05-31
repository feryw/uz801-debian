#/bin/bash

DIST=bookworm
BOOT_URL="https://github.com/Haris131/uz801v3-kernel/releases/download/v6.6.92/boot.img"
K_IMAGE_DEB_URL="https://github.com/Haris131/uz801v3-kernel/releases/download/v6.6.92/linux-image-6.6.92_6.6.92-gb46e298d66d7-1_arm64.deb"
K_HEADER_DEB_URL="https://github.com/Haris131/uz801v3-kernel/releases/download/v6.6.92/linux-headers-6.6.92_6.6.92-gb46e298d66d7-1_arm64.deb"
K_DEV_URL="https://github.com/Haris131/uz801v3-kernel/releases/tag/v6.6.92"
UUID=62ae670d-01b7-4c7d-8e72-60bcd00410b7

if [ `id -u` -ne 0 ]
  then echo "Please run as root"
  exit
fi

mkdir ../kernel
wget -P ../kernel "$BOOT_URL"
wget -P ../kernel "$K_IMAGE_DEB_URL"
wget -P ../kernel "$K_HEADER_DEB_URL"

mkdir debian build
debootstrap --arch=arm64 --foreign $DIST debian https://deb.debian.org/debian/
LANG=C LANGUAGE=C LC_ALL=C chroot debian /debootstrap/debootstrap --second-stage
cp ../deb-pkgs/*.deb ../kernel/linux-*.deb chroot.sh debian/tmp/
mount --bind /proc debian/proc
mount --bind /dev debian/dev
mount --bind /dev/pts debian/dev/pts
mount --bind /sys debian/sys
LANG=C LANGUAGE=C LC_ALL=C chroot debian /tmp/chroot.sh
umount debian/proc
umount debian/dev/pts
umount debian/dev
umount debian/sys
cp debian/etc/debian_version ./
mv debian/tmp/info.md ./
echo >> info.md
echo '## Enable Modem
```
sudo nmcli connection add type gsm ifname wwan0qmi0 con-name lte

sudo nmcli connection up lte
```

## Connect Wifi
```
sudo nmcli dev wifi connect "SSID" password "password"
```
' >> info.md
echo >> info.md
echo "🔗 [linux-libc-dev]($K_DEV_URL)" >> info.md
rm -rf debian/tmp/* debian/root/.bash_history > /dev/null 2>&1

dd if=/dev/zero of=debian-uz801v3.img bs=1M count=$(( $(du -ms debian | cut -f1) + 100 ))
mkfs.ext4 -L rootfs -U $UUID debian-uz801v3.img
mount debian-uz801v3.img build
rsync -aH debian/ build/
umount build
img2simg debian-uz801v3.img rootfs.img
rm -rf debian-uz801v3.img debian build > /dev/null 2>&1
