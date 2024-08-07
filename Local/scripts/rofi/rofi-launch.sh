#!/bin/sh

if ! command -v rofi 1>/dev/null || ! command -v bemoji; then
	echo "You need rofi and bemoji for this script to work"
	notify-send "Missing dependency"
fi

FLAGS="-disable-history -monitor -1 -show-icons -show"

if [ "$1" = alt-tab ]; then
	rofi $FLAGS
elif [ "$1" = menu ]; then
	rofi $FLAGS combi -display-drun '' -display-window '' combi \
	-display-combi '' -combi-modes window,drun -terminal "$TERMINAL"
elif [ "$1" = emoji ]; then
	bemoji -t
elif [ "$1" = power-menu ]; then
	rofi $FLAGS p -modi "p:rofi-power-menu"
fi

