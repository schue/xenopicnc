# Fetch cross compile tools
if [ ! -f master.tar.gz ]; then
    wget --no-check-certificate https://github.com/raspberrypi/tools/archive/master.tar.gz
    tar xzf master.tar.gz
fi

# Fetch 3.2.27 kernel
if [ ! -d linux-rpi-3.2.27 ]; then
    git clone -b rpi-3.2.27 --depth 1 git://github.com/raspberrypi/linux.git linux-rpi-3.2.27
fi

# Fetch firmware
if [ ! -d firmware ]; then
    git clone https://github.com/raspberrypi/firmware.git
fi

if [ ! -f xenomai-2.6.1.tar.bz2 ]; then
    wget http://download.gna.org/xenomai/stable/xenomai-2.6.1.tar.bz2
    tar xjf xenomai-2.6.1.tar.bz2
fi

if [ ! -d patch ]; then
    mkdir patch
    wget http://www.cim.mcgill.ca/~ian/rpi-linux-3.2.21-xenomai-2.6.1.patch -P patch
    wget http://dl.dropbox.com/u/17024524/linuxcnc/rpi-3.2.27-xenomai.patch -P patch

# Apply 3.2.27 patch
    patch -p0 < patch/rpi-3.2.27-xenomai.patch

# Apply Xenomai 2.6.1 patch
    xenomai-2.6.1/scripts/prepare-kernel.sh --arch=arm --linux=linux-rpi-3.2.27 --adeos=xenomai-2.6.1/ksrc/arch/arm/patches/ipipe-core-3.2.21-arm-1.patch

# Apply Rasbperry Pi Xenomai patch
    (cd linux-rpi-3.2.27; patch -p1 < ../patch/rpi-linux-3.2.21-xenomai-2.6.1.patch)
fi


# Create build directory
if [ ! linux-rpi-3.2.27/build ]; then
    mkdir linux-rpi-3.2.27/build

# Download and use minimal configuration file
    wget http://dl.dropbox.com/u/17024524/linuxcnc/config.rpi-3.2.27-xenomai%2B -O linux-rpi-3.2.27/build/.config
    cd linux-rpi-3.2.27
    make mrproper
    make ARCH=arm O=build oldconfig

# Compile
    make ARCH=arm O=build CROSS_COMPILE=../../tools-master/arm-bcm2708/arm-bcm2708hardfp-linux-gnueabi/bin/arm-bcm2708hardfp-linux-gnueabi-

# Install modules
    make ARCH=arm O=build INSTALL_MOD_PATH=dist modules_install

# Install headers
    make ARCH=arm O=build INSTALL_HDR_PATH=dist headers_install
    find build/dist/include \( -name .install -o -name ..install.cmd \) -delete
fi

# Install qemu tools
sudo apt-get install qemu qemu-user qemu-user-static binfmt-support debootstrap

if [ ! -d rootfs ]; then
    sudo debootstrap --foreign --no-check-gpg --include=ca-certificates --arch=armhf wheezy rootfs http://reflection.oss.ou.edu/raspbian/raspbian/
    sudo cp $(which qemu-arm-static) rootfs/usr/bin
    sudo chroot rootfs/ /debootstrap/debootstrap --second-stage --verbose
fi

sudo sh -c 'echo rpi-linuxcnc >rootfs/etc/hostname'
sudo sh -c 'echo -e 127.0.0.1\\trpi-linuxcnc >> rootfs/etc/hosts'
sudo sh -c 'cat> rootfs/etc/network/interfaces <<EOF
auto lo
iface lo inet loopback
auto eth0
iface eth0 inet dhcp
EOF
'

sudo sh -c 'cat> rootfs/etc/fstab <<EOF
proc /proc proc defaults 0 0
/dev/mmcblk0p1 /boot vfat defaults 0 0
EOF
'

sudo cp /etc/resolv.conf rootfs/etc
sudo chroot rootfs /bin/bash <<EOF
LC_ALL=C
LANGUAGE=C
LANG=C

echo "deb http://reflection.oss.ou.edu/raspbian/raspbian/ wheezy main" > /etc/apt/sources.list.d/raspbian.list

apt-get update
apt-get install -y --no-install-recommends locales sudo xauth bc openssh-server ntp gettext autoconf \
    libpth-dev gcc g++ make git libncurses5-dev libreadline-gplv2-dev tcl8.5-dev tk8.5-dev bwidget \
    blt libxaw7-dev libglu1-mesa-dev libgl1-mesa-dev libgtk2.0-dev python python-dev python-support \
    python-tk python-lxml libboost-python-dev yapps2-runtime libtk-img python-imaging python-imaging-tk \
    python-xlib python-gtkglext1 python-configobj python-glade2 python-numpy build-essential 
apt-get clean

addgroup xenomai
addgroup root xenomai

adduser rpi --gecos "RaspberryPi,,," --disabled-password
echo "rpi:pitime" | chpasswd
usermod -a -G xenomai,sudo,staff,kmem rpi

cat >/etc/udev/rules.d/xenomai.rules<<EOF
# allow RW access to /dev/mem
KERNEL=="mem", MODE="0660", GROUP="kmem" 
# real-time heap device (Xenomai:rtheap)
KERNEL=="rtheap", MODE="0660", GROUP=="xenomai"
# real-time pipe devices (Xenomai:rtpipe)
KERNEL=="rtp[0-9]*", MODE="0660", GROUP="xenomai"
EOF

sudo cp -a linux-rpi-3.2.27/build/dist/lib/modules rootfs/lib/
sudo cp -a linux-rpi-3.2.27/build/dist/include/* rootfs/usr/include
sudo cp linux-rpi-3.2.27/build/.config rootfs/boot/config-3.2.27-xenomai+
