#!/bin/sh

if ! command -v playerctl 1>/dev/null || ! command -v dunstify 1>/dev/null; then
	awk 'BEGIN {print "You need playerctl and dunstify for this script to work"}'
	notify-send "Missing dependency"
	exit 1
fi

if [ "$1" = READ-TITLE ]; then
	OLDOUT=""
	while true; do
	    OUT="$(playerctl metadata --format '{{ status }}: {{ title }}' 2>/dev/null | \
		awk '/Paused:|Stopped:/ {printf ("Paused"); exit} {sub($1 FS, ""); printf $0; exit}')"
	    if [ "$OUT" != "$OLDOUT" ]; then
	        awk -v v="$OUT" 'BEGIN { print v }'
	        OLDOUT="$OUT"
	    fi
	    sleep 0.5
	done
elif [ "$1" = READ-TIME ]; then
	OLDOUT=""
	while true; do
	    OUT="$(playerctl metadata --format "{{ duration(position) }}/{{ duration(mpris:length) }}" 2>/dev/null)"
	    if [ "$OUT" != "0:00/" ] && [ "$OUT" != "$OLDOUT" ]; then
	        awk -v v="$OUT" 'BEGIN { print v }'
	        OLDOUT="$OUT"
	    fi
	    sleep 1
	done
fi

if [ "$1" = VOL+ ]; then
	playerctl volume 0.10+
elif [ "$1" = VOL- ]; then
	playerctl volume 0.10-
elif [ "$1" = TOGGLEPLAY ]; then
	playerctl play-pause && sleep 0.1
	SONGINFO="$(playerctl metadata --format '{{ status }}: {{ title }} by {{ artist }}' 2>/dev/null \
	| awk '{if ($0 ~ /Paused: /) {print "PAUSED"} else {print $0}}')"
	[ -z "$SONGINFO" ] && exit 1
	dunstify -r 11 -t 2000 "Now Playing:" "$SONGINFO"
	awk -v v="$SONGINFO" 'BEGIN { print v }'
	exit 0
fi

VOLPERCENT=$(playerctl volume | awk '{printf "%.0f%s\n", $0*100, "%"; exit}')
dunstify -r 11 -t 1000 "Player Volume: $VOLPERCENT"
