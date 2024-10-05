#!/bin/sh

# CONTROLS SYSTEM VOLUME IN POLYBAR AND I3

# SAFETY CHECK
if ! command -v pactl 1>/dev/null || ! command -v dunstify 1>/dev/null; then
	echo "You need pamixer, pactl and dunstify for this script to work"
	notify-send "Missing dependency"
	exit 1
fi

vol="$(pactl list sinks | awk '/Volume:/ {printf("%.0f", $7); exit; }')"
[ "$vol" -gt 10 ] && pactl set-sink-volume @DEFAULT_SINK@ 65% # just in case

_increase_vol() {
	if [ "$2" = --NOLIMIT ]; then # ALLOWS VOLUME BEYOND 0dBFS (CLIPPING)
		[ "$vol" -lt 10 ] && pactl set-sink-volume @DEFAULT_SINK@ +5%
	else
		[ "$vol" -lt 0 ] || [ "$vol" = "-inf" ] \
		  && pactl set-sink-volume @DEFAULT_SINK@ +5%
		# sometimes the volume ends up being +1dB so we fix it
		[ "$vol" -gt 0 ] && pactl set-sink-volume @DEFAULT_SINK@ 100% || true
	fi
}

_decrease_vol() {
	pactl set-sink-volume @DEFAULT_SINK@ -5%
}

_toggle_mute() {
	pactl set-sink-mute @DEFAULT_SINK@ toggle || exit 1
	mute="$(pactl get-sink-mute @DEFAULT_SINK@ | grep -o 'yes\|no')"
	if [ "$mute" = "yes" ]; then
			dunstify -r 11 -t 1000 "Sound: Muted"
	else
			dunstify -r 11 -t 1000 "Sound: Unmuted"
	fi
}

_notify_vol() {
	vol="$(pactl list sinks | awk '/Volume:/ {printf("%.0f", $7); exit; }')"
	if [ "$vol" -gt 0 ]; then
		dunstify -r 111 -t 1000 -u critical "WARNING VOLUME IS OVER $vol dBFS"
		echo "WARNING VOLUME IS OVER $vol dBFS"
	else
		dunstify -r 11 -t 1000 "Main Vol: $vol dBFS"
		echo "$vol dBFS"
	fi
}

_print_help() {
	me="$(basename $0)"
	echo " USAGE:"
	echo " \"$me VOL+\""
	echo " \"$me VOL-\""
	echo " \"$me VOL+ --NOLIMIT\" - Allows setting volume beyond 0dBFS"
}

case "$1" in
	'VOL+')
		_increase_vol "$@" && _notify_vol
		;;
	'VOL-')
		_decrease_vol && _notify_vol
		;;
	'TOGGLEMUTE')
		_toggle_mute
		;;
	'--help')
		_print_help
		;;
	*)
		_print_help
		exit 1
		;;
esac
