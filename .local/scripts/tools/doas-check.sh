#!/bin/sh

BINDIR="${XDG_BIN_HOME:-$HOME/.local/bin}"
DOASCONF="${XDG_CONFIG_HOME:-$HOME/.config}/doas/doas.conf"
SUDO=$(command -v pkexec || command -v sudo)

cat "$DOASCONF" 1>/dev/null || { echo "MISSING $DOASCONF !" & notify-send -u critical "MISSING $DOASCONF"; exit 1; }

if [ "$(cat /etc/doas.conf)" != "$(cat "$DOASCONF")" ]; then
	"$SUDO" cp "$DOASCONF" /etc/doas.conf
	"$SUDO" chown root /etc/doas.conf
fi

ls /usr/local/bin/iotop  1>/dev/null || ( ls "$BINDIR"/iotop  && "$SUDO" ln -s "$BINDIR"/iotop  /usr/local/bin )
ls /usr/local/bin/ps_mem 1>/dev/null || ( ls "$BINDIR"/ps_mem && "$SUDO" ln -s "$BINDIR"/ps_mem /usr/local/bin )
ls /usr/local/bin/zramen 1>/dev/null || ( ls "$BINDIR"/zramen && "$SUDO" ln -s "$BINDIR"/zramen /usr/local/bin )
