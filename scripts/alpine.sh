# The work in this file is derived from https://github.com/pavel-demin/red-pitaya-notes. Please respect the accompanying license.

# Check if we are root, since chroot doesn't work otherwise
if [ "$(id -u)" -ne 0 ]; then
        echo 'This script must be run by root. Please execute `sudo -s` to do so.' >&2
        exit 1
fi

build_dir=build/linux-image
download_dir_local=downloads
download_dir=$build_dir/$download_dir_local

alpine_url=http://dl-cdn.alpinelinux.org/alpine/v3.14

uboot_tar=alpine-uboot-3.14.2-armv7.tar.gz
uboot_url=$alpine_url/releases/armv7/$uboot_tar

tools_tar=apk-tools-static-2.12.7-r0.apk
tools_url=$alpine_url/main/armv7/$tools_tar

firmware_tar=linux-firmware-other-20210716-r0.apk
firmware_url=$alpine_url/main/armv7/$firmware_tar

linux_dir=tmp/linux-5.10
linux_ver=5.10.80-xilinx

modules_dir=alpine-modloop/lib/modules/$linux_ver

passwd=root

echo "Downloading files if necessary and un-tar them..."
mkdir -p $download_dir

test -f $download_dir/$uboot_tar || curl -L $uboot_url -o $download_dir/$uboot_tar
test -f $download_dir/$tools_tar || curl -L $tools_url -o $download_dir/$tools_tar

test -f $download_dir/$firmware_tar || curl -L $firmware_url -o $download_dir/$firmware_tar

for tar in linux-firmware-ath9k_htc-20210716-r0.apk linux-firmware-brcm-20210716-r0.apk linux-firmware-cypress-20210716-r0.apk linux-firmware-rtlwifi-20210716-r0.apk
do
  url=$alpine_url/main/armv7/$tar
  test -f $download_dir/$tar || curl -L $url -o $download_dir/$tar
done

mkdir $build_dir/alpine-uboot
tar -zxf $download_dir/$uboot_tar --directory=$build_dir/alpine-uboot

mkdir $build_dir/alpine-apk
tar -zxf $download_dir/$tools_tar --directory=$build_dir/alpine-apk --warning=no-unknown-keyword

mkdir $build_dir/alpine-initramfs
cd $build_dir/alpine-initramfs

gzip -dc ../alpine-uboot/boot/initramfs-lts | cpio -id
rm -rf etc/modprobe.d
rm -rf lib/firmware
rm -rf lib/modules
rm -rf var
find . | sort | cpio --quiet -o -H newc | gzip -9 > ../initrd.gz

cd ..

echo "Creating image..."
mkimage -A arm -T ramdisk -C gzip -d initrd.gz uInitrd

mkdir -p $modules_dir/kernel

find $linux_dir -name \*.ko -printf '%P\0' | tar --directory=$linux_dir --owner=0 --group=0 --null --files-from=- -zcf - | tar -zxf - --directory=$modules_dir/kernel

cp $linux_dir/modules.order $linux_dir/modules.builtin $modules_dir/

echo "Running depmod..."
depmod -a -b alpine-modloop $linux_ver

tar -zxf $download_dir_local/$firmware_tar --directory=alpine-modloop/lib/modules --warning=no-unknown-keyword --strip-components=1 --wildcards lib/firmware/ar* lib/firmware/rt*

for tar in linux-firmware-ath9k_htc-20210716-r0.apk linux-firmware-brcm-20210716-r0.apk linux-firmware-cypress-20210716-r0.apk linux-firmware-rtlwifi-20210716-r0.apk
do
  tar -zxf $download_dir_local/$tar --directory=alpine-modloop/lib/modules --warning=no-unknown-keyword --strip-components=1
done

mksquashfs alpine-modloop/lib modloop -b 1048576 -comp xz -Xdict-size 100%

rm -rf alpine-uboot alpine-initramfs initrd.gz alpine-modloop

root_dir=alpine-root

mkdir -p $root_dir/usr/bin
cp /usr/bin/qemu-arm-static $root_dir/usr/bin/

mkdir -p $root_dir/etc
cp /etc/resolv.conf $root_dir/etc/

mkdir -p $root_dir/etc/apk
mkdir -p $root_dir/media/mmcblk0p1/cache
ln -s /media/mmcblk0p1/cache $root_dir/etc/apk/cache

cp ../../linux-image/uEnv.txt .

cp -r ../../linux-image/alpine/etc $root_dir/
#cp -r ../../linux-image/alpine/apps $root_dir/media/mmcblk0p1/
mkdir -p $root_dir/media/mmcblk0p1/apps

# Copy current status of RedPitayaDAQServer directory
rsync -av -q ../../ $root_dir/media/mmcblk0p1/apps/RedPitayaDAQServer --exclude build --exclude .Xil --exclude "red-pitaya-alpine*.zip"

# Reset repository
git remote set-url origin https://github.com/tknopp/RedPitayaDAQServer.git
git config user.name "rp_local"
git config user.email "n.a."

cp -r alpine-apk/sbin $root_dir/

chroot $root_dir /sbin/apk.static --repository $alpine_url/main --update-cache --allow-untrusted --initdb add alpine-base

echo $alpine_url/main > $root_dir/etc/apk/repositories
echo $alpine_url/community >> $root_dir/etc/apk/repositories

chroot $root_dir /bin/sh <<- EOF_CHROOT

apk update
apk add openssh ucspi-tcp6 iw wpa_supplicant dhcpcd dnsmasq hostapd iptables avahi dbus dcron chrony gpsd libgfortran musl-dev fftw-dev libconfig-dev alsa-lib-dev alsa-utils curl wget less nano bc dos2unix patch make git build-base gfortran gdb htop python3 expect

ln -sf python3 /usr/bin/python

rc-update add bootmisc boot
rc-update add hostname boot
rc-update add hwdrivers boot
rc-update add modloop boot
rc-update add swclock boot
rc-update add sysctl boot
rc-update add syslog boot
rc-update add urandom boot

rc-update add killprocs shutdown
rc-update add mount-ro shutdown
rc-update add savecache shutdown

rc-update add devfs sysinit
rc-update add dmesg sysinit
rc-update add mdev sysinit

rc-update add avahi-daemon default
rc-update add chronyd default
rc-update add dhcpcd default
rc-update add local default
rc-update add dcron default
rc-update add sshd default

mkdir -p etc/runlevels/wifi
rc-update -s add default wifi

rc-update add iptables wifi
rc-update add dnsmasq wifi
rc-update add hostapd wifi

sed -i 's/^SAVE_ON_STOP=.*/SAVE_ON_STOP="no"/;s/^IPFORWARD=.*/IPFORWARD="yes"/' etc/conf.d/iptables

sed -i 's/^#PermitRootLogin.*/PermitRootLogin yes/' etc/ssh/sshd_config
chmod 400 /etc/ssh/*

#ssh-keygen -t rsa -b 2048 -m PEM -f /media/mmcblk0p1/apps/RedPitayaDAQServer/rootkey  -q -N ""
#/media/mmcblk0p1/apps/RedPitayaDAQServer/scripts/add_key
mkdir /media/mmcblk0p1/.ssh
cp /media/mmcblk0p1/apps/RedPitayaDAQServer/rootkey.pub /media/mmcblk0p1/.ssh/authorized_keys

echo root:$passwd | chpasswd

setup-hostname red-pitaya
hostname red-pitaya

sed -i 's/^# LBU_MEDIA=.*/LBU_MEDIA=mmcblk0p1/' etc/lbu/lbu.conf

cat <<- EOF_CAT > root/.profile
alias rw='mount -o rw,remount /media/mmcblk0p1'
alias ro='mount -o ro,remount /media/mmcblk0p1'
EOF_CAT

cat <<- EOF_CAT >> /etc/fstab
/dev/mmcblk0p1 /media/mmcblk0p1 vfat rw,relatime,fmask=0022,dmask=0022,codepage=437,iocharset=iso8859-1,shortname=mixed,errors=remount-ro 0 0
tmpfs / tmpfs rw,relatime,size=1048576k,mode=755 0 0
EOF_CAT

cat <<- 'EOF_CAT' > /etc/motd
Welcome to the Red Pitaya DAQ Server Alpine Linux!

Please head to ~/apps/RedPitayaDAQServer for working with the server and its components.
For further help please refer to the documentation at https://tknopp.github.io/RedPitayaDAQServer/dev/index.html.
EOF_CAT

ln -s /media/mmcblk0p1/apps root/apps
ln -s /media/mmcblk0p1/wifi root/wifi

lbu add root
lbu delete etc/resolv.conf
lbu delete root/.ash_history

git config --global --add safe.directory /media/mmcblk0p1/apps/RedPitayaDAQServer
git config --global --add safe.directory /media/mmcblk0p1/apps/RedPitayaDAQServer/libs/scpi-parser

#make -C /media/mmcblk0p1/apps/RedPitayaDAQServer clean
make -C /media/mmcblk0p1/apps/RedPitayaDAQServer server

lbu include /etc/init.d
lbu commit -d

EOF_CHROOT

cp -r $root_dir/media/mmcblk0p1/apps .
cp -r $root_dir/media/mmcblk0p1/cache .
cp $root_dir/media/mmcblk0p1/red-pitaya.apkovl.tar.gz .

cp -r ../../linux-image/alpine/wifi .

hostname -F /etc/hostname

rm -rf $root_dir alpine-apk

zip -r -q red-pitaya-alpine-3.14-armv7-`date +%Y%m%d`.zip apps boot.bin cache devicetree.dtb modloop red-pitaya.apkovl.tar.gz uEnv.txt uImage uInitrd wifi

rm -rf apps cache modloop red-pitaya.apkovl.tar.gz uInitrd wifi

mv red-pitaya-alpine-3.14-armv7-`date +%Y%m%d`.zip ../../
cd ../../
echo "Finished building linux image"
