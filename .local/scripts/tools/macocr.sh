#!/bin/sh

# Safety check
if ! command -v tesseract >/dev/null 2>&1; then
	echo "You need tesseract for this script to work"
	notify-send "Missing dependency!"
	exit 1
fi

OCRPATH="${XDG_CACHE_HOME:-$HOME/.cache}"/tesseract
OCR="$OCRPATH"/OCR
mkdir -p "$OCRPATH"

notify-send "Processing image"

tesseract "$@" "$OCR" && mv "$OCR".txt "$OCR" # mv is a hack because tesseract adds a useless .txt to the file

if [ -z $(cat "$OCR") ]; then
    notify-send "Failed to get text"; exit 1
else
    xclip -selection clipboard -i < "$OCR" && notify-send "MacOS moment"
fi
