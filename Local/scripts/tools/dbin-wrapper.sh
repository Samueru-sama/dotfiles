#!/bin/sh

# can't get used to dbin flags lol

DBIN="$XDG_SBIN_HOME/dbin"
if [ ! -e "$DBIN" ]; then
	echo "dbin is not installed or this script has the wrong path"
	exit 1
fi

case "$1" in
	'-i')
		shift
		"$DBIN" install "$@"
		;;
	'-r')
		shift
		"$DBIN" remove "$@"
		;;
	'-l')
		shift
		"$DBIN" list "$@"
		;;
	'-u')
		shift
		"$DBIN" update "$@"
		;;
	'-q')
		shift
		"$DBIN" search "$@"
		;;
	*)
		"$DBIN" "$@"
		;;
esac
