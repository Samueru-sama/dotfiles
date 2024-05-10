#!/bin/sh

# Similar to xhog in voidlinux
pacman -Qi | awk -F': ' '/Name/ {name=$2} /Installed Size/ {size=$2} name && size {print name, size; name=size=""}' | column -t | grep MiB | sort -nk 2
