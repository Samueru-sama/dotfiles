#!/bin/sh

# Used with thunar to convert webp images to png

if ! command -v dwebp; then
	echo "You need tesseract for this script to work"
	notify-send "Missing dependency!"
	exit 1
fi

for files in "$@"; do 
	dwebp "$files" -o "${files%.*}".png 
done
