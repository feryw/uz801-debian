#!/bin/bash

LANG_TARGET=en_US.UTF-8
PASSWORD=1234
NAME=uz801v3
PARTUUID=a7ab80e8-e9d1-e8cd-f157-93f69b1d141e

cat <<EOF > /etc/apt/sources.list
deb http://deb.debian.org/debian/ bookworm main contrib non-free non-free-firmware
# deb-src http://deb.debian.org/debian/ bookworm main contrib non-free non-free-firmware

deb http://deb.debian.org/debian/ bookworm-updates main contrib non-free non-free-firmware
# deb-src http://deb.debian.org/debian/ bookworm-updates main contrib non-free non-free-firmware

deb http://deb.debian.org/debian/ bookworm-backports main contrib non-free non-free-firmware
# deb-src http://deb.debian.org/debian/ bookworm-backports main contrib non-free non-free-firmware

deb http://security.debian.org/debian-security bookworm-security main contrib non-free non-free-firmware
# deb-src http://security.debian.org/debian-security bookworm-security main contrib non-free non-free-firmware
EOF

cat <<EOF > /etc/fstab
PARTUUID=$PARTUUID / ext4 defaults,noatime,commit=600,errors=remount-ro 0 1
tmpfs /tmp tmpfs defaults,nosuid 0 0
EOF

apt-get update
apt-get full-upgrade -y
apt-get install -y locales network-manager openssh-server systemd-timesyncd fake-hwclock zram-tools rmtfs qrtr-tools sudo curl wget neofetch
apt-get install -y /tmp/*.deb
ln -sf /usr/share/zoneinfo/Asia/Jakarta /etc/localtime
timedatectl set-ntp 1
sed -i -e "s/# $LANG_TARGET UTF-8/$LANG_TARGET UTF-8/" /etc/locale.gen
dpkg-reconfigure --frontend=noninteractive locales
update-locale LANG=$LANG_TARGET LC_ALL=$LANG_TARGET LANGUAGE=$LANG_TARGET
echo -n >/etc/resolv.conf
echo -e "$PASSWORD\n$PASSWORD" | passwd
echo $NAME > /etc/hostname
sed -i "1a 127.0.0.1\t$NAME" /etc/hosts
sed -i "s/::1\t\tlocalhost/::1\t\tlocalhost $NAME/g" /etc/hosts
sed -i 's/^.\?PermitRootLogin.*$/PermitRootLogin yes/g' /etc/ssh/sshd_config
sed -i 's/^.\?ALGO=.*$/ALGO=lzo-rle/g' /etc/default/zramswap
sed -i 's/^.\?PERCENT=.*$/PERCENT=300/g' /etc/default/zramswap

# Add user
adduser --disabled-password --comment "" chewy
# Set password
passwd chewy << EOD
$PASSWORD
$PASSWORD
EOD
# Add user to sudo group
usermod -aG sudo chewy

cat <<EOF >> /etc/bash.bashrc

alias ls='ls --color=auto -lh'
alias ll='ls --color=auto -lhA'
alias l='ls --color=auto -l'
alias cl='clear'
alias ip='ip --color'
alias bridge='bridge -color'
alias free='free -h'
alias df='df -h'
alias du='du -hs'

EOF

cat <<EOF >> /home/chewy/.bashrc

clear
/usr/bin/neofetch
EOF

echo "## Default Configuration" > /tmp/info.md
vmlinuz_name=$(basename /boot/vmlinuz-*)
cat <<EOF >> /tmp/info.md
- Kernel version: ${vmlinuz_name#*-}
- Default username: root / chewy
- Default password: $PASSWORD
- WiFi name: openstick
- WiFi password: 12345678
EOF
rm -rf /etc/ssh/ssh_host_* /var/lib/apt/lists
apt clean
exit

