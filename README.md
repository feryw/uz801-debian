# uz801v3-debian
Debian build script for UZ801_V3.2

## Features
- NFS client v2/v3/v4, NFS server v3/v4
- KSMBD
- Default 300% zram
- Kernel overclocked to 1.4GHz

## Manually change the kernel
```shell
cd /tmp
wget KERN_DEB_URL
wget BOOT_IMG_URL
apt purge linux-image*
apt install ./linux-image*.deb
dd if=/tmp/boot.img of=/dev/disk/by-partlabel/boot bs=1M
reboot
```

## Local build 
1. Clone this repository
2. Install the package `debootstrap rsync qemu-user-static binfmt-support android-sdk-libsparse-utils`
3. Enter the rootfs directory and run `build.sh` with root privileges
4. After the build is complete, you will get rootfs.img in the rootfs directory and boot.img in the kernel directory
