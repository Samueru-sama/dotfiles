#!/bin/sh

# This script is used to control deadbeef with i3wm
# Deadbeef has to be configured to hide to tray when closed
# You can hide the systray icon and it will work still

if ! command -v deadbeef 1>/dev/null || ! command -v playerctl 1>/dev/null \
	|| ! command -v xdo 1>/dev/null || ! command -v xdotool 1>/dev/null; then
	printf "You need deadbeef, xdo, xdotool and playerctl for this script to work"
	notify-send "Missing dependency"
	exit 1
fi

WCLASS=$(xdotool getactivewindow getwindowclassname)
tmp_dir="${TMPDIR:-/tmp}/getbeef"
mkdir -p "$tmp_dir" && chmod -R 700 "$tmp_dir" || exit 1

if [ "$1" = "REPEAT" ]; then
	if pgrep "deadbeef" 1>/dev/null; then
		LOOP="$(playerctl loop --appimage-extract-and-run)"
		if [ "$LOOP" = "None" ]; then
			playerctl loop Track && notify-send -t 700 "Repeat Track On"
		else
			playerctl loop None && notify-send -t 700 "Repeat Track Off"
		fi
	else
		echo "DeaDBeeF is not running"
		exit 1
	fi
elif [ "$1" = "SHUFFLE" ]; then
	if pgrep "deadbeef" 1>/dev/null; then
		SHUFFLE=$(playerctl shuffle --appimage-extract-and-run)
		if [ "$SHUFFLE" = "Off" ]; then
			playerctl shuffle On && notify-send -t 700 "Shuffle On"
		else
			playerctl shuffle Off && notify-send -t 700 "Shuffle Off"
		fi
	else
		echo "DeaDBeeF is not running"
		exit 1
	fi
elif [ "$WCLASS" = "Deadbeef" ]; then
	WID="$(xdo id)"
	xdo hide && echo "$WID" > "$tmp_dir"/deadbeefid
else
	WID=$(cat "$tmp_dir"/deadbeefid)
	[ -n "$WID" ] && xdo show "$WID" && xdo activate "$WID"
	pgrep deadbeef || { notify-send "Launching DeaDBeef"; exec deadbeef; }
fi
