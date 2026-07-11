#!/bin/sh

set -e

for cmd in deadbeef playerctl; do
	if ! command -v "$cmd" 1>/dev/null; then
		>&2 echo "Missing dependency: $cmd"
		notify-send "Missing dependency: $cmd"
		exit 1
	fi
done

case "$1" in
	REPEAT)
		LOOP=$(playerctl loop)
		if [ "$LOOP" = "None" ]; then
			playerctl loop Track
			notify-send -t 700 "Repeat Track On"
		else
			playerctl loop None
			notify-send -t 700 "Repeat Track Off"
		fi
		;;
	SHUFFLE)
		SHUFFLE=$(playerctl shuffle)
		if [ "$SHUFFLE" = "Off" ]; then
			playerctl shuffle On
			notify-send -t 700 "Shuffle On"
		else
			playerctl shuffle Off
			notify-send -t 700 "Shuffle Off"
		fi
		;;
esac

