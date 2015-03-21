#!/bin/bash
apt-get clean 
rm /var/cache/apt/archive/* /var/cache/apt/* /var/lib/apt/* 2> /dev/null || true
