#!/bin/sh

# CONTROLS MEDIA PLAYERS IN POLYBAR AND I3

if ! command -v playerctl 1>/dev/null || ! command -v dunstify 1>/dev/null; then
	awk 'BEGIN {print "You need playerctl and dunstify for this script to work"}'
	notify-send "Missing dependency"
	#exit 1
fi

HACK="--appimage-extract-and-run" # Allows sandboxed appimages to launch other appimages

if [ "$1" = VOL+ ]; then
	playerctl volume 0.10+ "$HACK"
elif [ "$1" = VOL- ]; then
	playerctl volume 0.10- "$HACK"
elif [ "$1" = TOGGLEPLAY ]; then
	playerctl play-pause --appimage-extract-and-run && sleep 0.1
	SONGINFO="$(playerctl metadata --format '{{ status }}: {{ title }} by {{ artist }}' 2>/dev/null \
	| awk '{if ($0 ~ /Paused: /) {print "PAUSED"} else {print $0}}')"
	[ -z "$SONGINFO" ] && exit 1
	notify-send "Now Playing:" "$SONGINFO"
	awk -v v="$SONGINFO" 'BEGIN { print v }'
	exit 0
fi

VOLPERCENT=$(awk -v vol="$(playerctl volume --appimage-extract-and-run )" 'BEGIN {printf "%.0f%%", vol * 100}')
dunstify -r 11 -t 1000 "Player Volume: $VOLPERCENT" "$HACK"

