#!/bin/sh
set -eu
gcc -fPIC -o ./getdbvol ./getdbvol.c -lpulse
wget https://raw.githubusercontent.com/pkgforge-dev/Anylinux-AppImages/refs/heads/main/useful-tools/quick-sharun.sh -O /tmp/quick-sharun
chmod +x /tmp/quick-sharun
APPDIR=./AppDir /tmp/quick-sharun --make-static-bin ./getdbvol
mv ./AppDir/bin/getdbvol ./
rm -rf ./AppDir
