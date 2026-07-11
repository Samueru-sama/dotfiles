#!/bin/sh

# USED WITH POLYBAR TO CHANGE THE CPUSCHEDULER WHEN CLICKING ON THE CPU MODULE

set -e

for cmd in cpupower notify-send; do
	if ! command -v "$cmd" 1>/dev/null; then
		>&2 echo "${0##*/} Missing dependency '$cmd'!"
		notify-send "${0##*/} Missing dependency '$cmd'!" || :
		exit 1
	fi
done

_read() { read -r "$1" < "/sys/devices/system/cpu/cpu0/cpufreq/$2"; }

_set_powersave()   { doas cpupower frequency-set -g powersave; }
_set_performance() { doas cpupower frequency-set -g performance; }
# some systems don't have schedutil, so we fallback to powersave
_set_schedutil()   { doas cpupower frequency-set -g schedutil || _set_powersave; }
_notify() {
	_read GOVERNOR scaling_governor
	echo "CPU: $GOVERNOR"
	notify-send "CPU:" "$GOVERNOR"
	exit 0
}

_read GOVERNOR scaling_governor

if [ -z "$1" ]; then
	case "$GOVERNOR" in
		powersave)  _set_schedutil;;
		schedutil)  _set_powersave;;
		*)          _set_schedutil;;
	esac
	_notify
else
	case "$1" in
		--check)       _notify;;
		--performance) _set_performance;;
		--balanced)    _set_schedutil;;
		--powersave)   _set_powersave;;
		*)             >&2 echo "ERROR: Unknown option $1"
	esac
fi
