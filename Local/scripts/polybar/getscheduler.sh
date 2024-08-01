#!/bin/sh

# USED WITH POLYBAR TO CHANGE THE CPUSCHEDULER WHEN CLICKING ON THE CPU MODULE

# SAFETY CHECK
if ! command -v cpupower 1>/dev/null || ! command -v dunstify 1>/dev/null; then
	echo "You need cpupower and dunstify for this script to work"
	notify-send "Missing dependency!"
	exit 1
fi

_governor () {
	GOVERNOR=$(cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor 2>/dev/null)
}

_notify () {
	[ -z $GOVERNOR ] && exit 1
	echo "CPU scheduler set: $GOVERNOR"
	notify-send "CPU scheduler set:" "$GOVERNOR"
	exit 0
}

_governor

# WHEN CALLED WITHOUT ANY FLAGS THE SCRIPT WILL TOGGLE BETWEEN SCHEDUTIL AND POWERSAVE
if [ -z "$@" ]; then
	if [ "$GOVERNOR" = "schedutil" ]; then
		doas cpupower frequency-set -g powersave || exit 1
	elif [ "$GOVERNOR" = "powersave" ]; then
		doas cpupower frequency-set -g schedutil || exit 1
	else
		doas cpupower frequency-set -g powersave || exit 1
	fi
	_governor
	_notify
fi	

# NOTIFIES THE CURRENT GOVERNOR
if [ "$1" = "--CHECK" ]; then
	_notify
fi

# Change CPU governor
if [ "$1" = "--SAVE" ]; then
    doas cpupower frequency-set -g powersave || exit 1
	_governor
	_notify
elif [ "$1" = "--PERFORMANCE" ]; then
    doas cpupower frequency-set -g performance || exit 1
	_governor
	_notify
elif [ "$1" = "--BALANCED" ]; then
    doas cpupower frequency-set -g schedutil || exit 1
	_governor
	_notify
fi

