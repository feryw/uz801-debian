#/bin/bash

if [ $(echo "${1}" | grep "arm64") ]; then
  DISTRO_ARCH="arm64"
else
  DISTRO_ARCH="armhf"
fi

DIST=bookworm
REPO_URL="https://api.github.com/repos/haris131/uz801v3-kernel/releases"
BOOT_URL="$(curl -sL "${REPO_URL}" | sed -e 's|"||g' -e 's| ||g' | grep "${1}" | sed -e's|browser_download_url:||g' -e 's|,||g' | grep boot.img | awk '{print $1}')"
K_IMAGE_DEB_URL="$(curl -sL "${REPO_URL}" | sed -e 's|"||g' -e 's| ||g' | grep "${1}" | sed -e's|browser_download_url:||g' -e 's|,||g' | grep linux-image | awk '{print $1}')"
K_HEADER_DEB_URL="$(curl -sL "${REPO_URL}" | sed -e 's|"||g' -e 's| ||g' | grep "${1}" | sed -e's|browser_download_url:||g' -e 's|,||g' | grep linux-headers | awk '{print $1}')"
K_DEV_URL="$(curl -sL "${REPO_URL}" | sed -e 's|"||g' -e 's| ||g' | grep "${1}" | sed -e's|browser_download_url:||g' -e 's|,||g' | grep html_url | awk -F 'html_url:' '{print $2}')"
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
debootstrap --arch=${DISTRO_ARCH} --foreign $DIST debian https://deb.debian.org/debian/
LANG=C LANGUAGE=C LC_ALL=C chroot debian /debootstrap/debootstrap --second-stage
cp ../deb-pkgs/firmware-uz801v3.deb ../deb-pkgs/${1}/openstick-utils-all.deb ../kernel/linux-*.deb chroot.sh debian/tmp/
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

wget --no-check-certificate https://github.com/Haris131/speedtest/raw/main/ram.py -O debian/usr/bin/ram && chmod +x debian/usr/bin/ram && sed -i 's|#!/usr/bin/env python|#!/usr/bin/env python3|g' debian/usr/bin/ram
wget --no-check-certificate https://github.com/Haris131/speedtest/raw/main/speedtest -O debian/usr/bin/speedtest && chmod +x debian/usr/bin/speedtest
wget --no-check-certificate https://raw.githubusercontent.com/satriakanda/mmsms/refs/heads/main/mmsms -O debian/usr/bin/mmsms && chmod +x debian/usr/bin/mmsms

dd if=/dev/zero of=debian-uz801v3.img bs=1M count=$(( $(du -ms debian | cut -f1) + 100 ))
mkfs.ext4 -L rootfs -U $UUID debian-uz801v3.img
mount debian-uz801v3.img build
rsync -aH debian/ build/
umount build
img2simg debian-uz801v3.img rootfs.img
rm -rf debian-uz801v3.img debian build > /dev/null 2>&1
