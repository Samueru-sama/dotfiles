#!/bin/sh

# SAFETY CHECK
if ! command -v pulsemixer 1>/dev/null || ! command -v pactl 1>/dev/null || ! command -v dunstify 1>/dev/null; then
	awk 'BEGIN {print "You need pulsemixer, pactl and dunstify for this script to work"}'
	notify-send "Missing dependency"
	exit 1
fi

# CONTROLS VOLUME THRU POLYBAR
if [ "$1" = VOL+ ]; then
	if [ "$2" = --NOLIMIT ]; then # --NOLIMIT ALLOWS THE VOLUME BEYOND 0dBFS (CLIPPING)
		pulsemixer --change-volume +5 --unmute --max-volume 145
	else
		pulsemixer --change-volume +5 --unmute --max-volume 100
	fi
elif [ "$1" = VOL- ]; then
	if [ "$2" = --NOLIMIT ]; then
		pulsemixer --change-volume -5 --unmute --max-volume 145
	else
		pulsemixer --change-volume -5 --unmute --max-volume 100
	fi
elif [ "$1" = TOGGLEMUTE ]; then
	pactl set-sink-mute @DEFAULT_SINK@ toggle && dunstify -r 11 -t 1000 \
	"$(awk 'BEGIN { cmd = "pactl get-sink-mute @DEFAULT_SINK@"; if ((cmd | getline) > 0) 
	if (/Mute: yes/) {print "Sound: Muted"; exit} else {print "Sound: Unmuted"; exit}}')"
	exit 0
fi

# NOTIFIES VOLUME CHANGES
CURRENTVOL="$(awk 'BEGIN { cmd = "pactl list sinks"; while ((cmd | getline) > 0) 
			if (/Volume:/) {printf("%.0f", $7); exit; } close(cmd); }' )"

if [ "$CURRENTVOL" -gt 0 ]; then
	dunstify -r 111 -t 1000 "WARNING VOLUME IS OVER $CURRENTVOL dBFS"
	awk -v v="WARNING VOLUME IS OVER $CURRENTVOL dBFS" 'BEGIN { print v }'
else
	dunstify -r 11 -t 1000 "Main Vol: $CURRENTVOL dBFS"
	awk -v v="$CURRENTVOL dBFS" 'BEGIN { print v }'
fi
