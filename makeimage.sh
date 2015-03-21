#!/bin/bash
dd if=/dev/zero of=rpi-lcnc.img count=0 bs=1 seek=2021654528

sudo sh -c 'cat <<EOF | sfdisk --force rpi-lcnc.img
unit: sectors
1 : start=     2048, size=   204800, Id= c
2 : start=   206848, size=  3741696, Id=83
EOF
'

sudo losetup /dev/loop0 rpi-lcnc.img -o $((2048*512))
sudo mkfs.vfat -F 32 -n BOOT /dev/loop0
sudo losetup -d /dev/loop0
sudo losetup /dev/loop0 rpi-lcnc.img -o $((206848*512))
sudo mkfs.ext4 -L ROOT /dev/loop0
sudo losetup -d /dev/loop0

mkdir -p mnt/{boot,root}
sudo mount -o loop,offset=$((2048*512)) rpi-lcnc.img mnt/boot
sudo mount -o loop,offset=$((206848*512)) rpi-lcnc.img mnt/root

sudo rsync -a rootfs/ mnt/root/
sudo cp -a firmware/hardfp/opt/vc mnt/root/opt/

sudo cp rootfs/boot/* mnt/boot/
sudo cp firmware/boot/{*bin,*dat,*elf} mnt/boot/
sudo cp linux-rpi-3.2.27/build/arch/arm/boot/Image mnt/boot/kernel.img
sudo sh -c 'cat >mnt/boot/config.txt<<EOF
kernel=kernel.img
arm_freq=800
core_freq=250
sdram_freq=400
over_voltage=0
gpu_mem=16
EOF
'
sudo sh -c 'cat >mnt/boot/cmdline.txt<<EOF
xeno_nucleus.xenomai_gid=1000 dwc_otg.lpm_enable=0 console=ttyAMA0,115200 kgdboc=ttyAMA0,115200 root=/dev/mmcblk0p2 rootfstype=ext4 elevator=deadline rootwait
EOF
'   

sudo umount mnt/{boot,root}
bzip2 -9 rpi-lcnc.img
#sudo sh -c 'bzcat rpi-lcnc.img.bz2 > /dev/<sdcard>'
