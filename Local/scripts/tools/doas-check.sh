#!/bin/sh

BINDIR="${XDG_BIN_HOME:-$HOME/.local/bin}"
DOASCONF="${XDG_CONFIG_HOME:-$HOME/.config}/doas/doas.conf"
SUDO=$(command -v pkexec || command -v sudo)

if [ ! -f "$DOASCONF" ]; then
	echo "MISSING \"$DOASCONF\"!"
	notify-send -u critical "MISSING $DOASCONF"
	exit 1
fi
if [ "$(cat /etc/doas.conf)" != "$(cat "$DOASCONF")" ]; then
	"$SUDO" cp "$DOASCONF" /etc/doas.conf
	"$SUDO" chown root /etc/doas.conf
fi

if [ ! -L /usr/local/bin/iotop ]; then
	[ -f "$BINDIR"/iotop ] && "$SUDO" ln -s "$BINDIR"/iotop  /usr/local/bin
fi

if [ ! -L /usr/local/bin/ps_mem ]; then
	[ -f "$BINDIR"/ps_mem ] && "$SUDO" ln -s "$BINDIR"/ps_mem /usr/local/bin
fi

if [ ! -L /usr/local/bin/zramen ]; then
	[ -f "$BINDIR"/zramen ] && "$SUDO" ln -s "$BINDIR"/zramen /usr/local/bin
fi
