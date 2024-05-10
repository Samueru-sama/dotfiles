#!/bin/sh

# This script is used to control deadbeef with i3wm
# Deadbeef has to be configured to hide to tray when closed 
# You can hide the systray icon and it will work still

if ! command -v deadbeef 1>/dev/null || ! command -v i3-msg 1>/dev/null || ! command -v playerctl 1>/dev/null; then
	awk 'BEGIN {print "You need deadbeef, i3 and playerctl for this script to work"}'
	notify-send "Missing dependency"
	exit 1
fi

if [ "$1" = "REPEAT" ]; then
	if pgrep "deadbeef" 1>/dev/null; then
		LOOP=$(playerctl loop)
		if [ "$LOOP" = "None" ]; then
			playerctl loop Track && dunstify -r 33 -t 1500 "Repeat Track On"
		else
			playerctl loop None && dunstify -r 33 -t 1500 "Repeat Track Off"
		fi
	else
		echo "DeaDBeeF is not running"
		exit 1
	fi
	exit 0
elif [ "$1" = "SHUFFLE" ]; then
	if pgrep "deadbeef" 1>/dev/null; then
		SHUFFLE=$(playerctl shuffle)
		if [ "$SHUFFLE" = "Off" ]; then
			playerctl shuffle On && dunstify -r 33 -t 1500 "Shuffle On"
		else
			playerctl shuffle Off && dunstify -r 33 -t 1500 "Shuffle Off"
		fi
	else
		echo "DeaDBeeF is not running"
		exit 1
	fi
	exit 0
fi

WCLASS=$(i3-msg -t get_tree | gron.awk | awk -F "=|\"" '/window.properties.class.*Deadbeef/ {print $3}')

if pgrep deadbeef 1>/dev/null; then
    if [ "$WCLASS" = "Deadbeef" ]; then
        i3-msg "[class=Deadbeef] kill"
    else
        i3-msg "[class=Deadbeef] focus" >/dev/null 2>&1 || deadbeef 2>/dev/null || exit 1
        dunstify -r 33 -t 700 "DeaDBeef"
    fi
else
    deadbeef 2>/dev/null || exit 1
    dunstify -r 36 -t 1500 "Launching DeaDBeef"
fi
