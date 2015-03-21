rm -r tools-master

cd linux-rpi-3.2.27
git reset --hard
cd ..

cd firmware
git reset --hard
cd ..

rm -r xenomai-2.6.1

rm -r patch
