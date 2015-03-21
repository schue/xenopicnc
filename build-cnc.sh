#!/bin/bash
sudo cp -a xenomai-2.6.1 rootfs/usr/src

if [ ! -d emc2-dev ]; then
    git clone -b rtos-integration-preview3 --depth 1 git://git.mah.priv.at/emc2-dev.git
fi
sudo cp -a emc2-dev rootfs/usr/src/

sudo chroot rootfs <<EOF
cd /usr/src/xenomai-2.6.1
./configure
make DESTDIR=\$(pwd)/rpi install
tar cf - -C rpi usr/xenomai/{bin,lib,sbin,include} | tar xvf - -C /
echo /usr/xenomai/lib/ > /etc/ld.so.conf.d/xenomai.conf
ldconfig -v

make clean
rm -r rpi

cd ../emc2-dev/src
./autogen.sh
./configure --prefix=/usr/local --with-platform=raspberry --disable-build-documentation --with-kernel=/boot/config-3.2.27-xenomai+
make
make install

make clean
exit
EOF
