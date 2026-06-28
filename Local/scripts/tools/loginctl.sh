#!/bin/sh

# Wrapper script that syncs the browser cache in tmpfs before reboot/power-off
killall brave >/dev/null 2>&1
if command -v tmpfs 1>/dev/null; then
	if ! tmpfs --sync-now >/dev/null 2>&1; then
		echo "Error tmpfs.sh failed"
		exit 1
	fi
fi

if [ "$1" = "terminate-session" ]; then
	# This fixes a weird bug in Voidlinux where TTY freezes when logging out
	# Also fixes a bug in Artixlinux where loginctl doesn't do anything
	i3-msg exit
	sleep 1
	clear
	pkill -9 -u "$UID"
else
	exec /usr/bin/loginctl "$@"
fi
