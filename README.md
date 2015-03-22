# Xenomai + Raspberry Pi + Linux CNC

These scripts sort of mostly help you automatically build the real-time Xenomai kernel and Linux CNC for the Raspberry Pi. They have been tested on Debian Wheezy.

Run build.sh and then makeimage.sh this will give you a file that you can dd onto your SD card.

## Files

* build.sh - The main build script
* build-cnc.sh - This step takes a while and gave me a few troubles so it is currently separated out. The build.sh script calls it.
* clean.sh - Attempts to reset things so that you can start fresh.
* makeimage.sh - Builds an image file that you can write to an SD card.
