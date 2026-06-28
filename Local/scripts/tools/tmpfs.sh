#!/bin/sh

# this script assumes that Zen browser is wrapped with a fake home
# in $XDG_CONFIG_HOME/zen-browser
BROWSERS="firedragon"
CONFIGDIR="${XDG_CONFIG_HOME:-$HOME/.config}"
CACHEDIR="${XDG_CACHE_HOME:-$HOME/.cache}"/tmpfs
OKFILE="$CACHEDIR"/tmpfsOK

if ! command -v rsync 1>/dev/null; then
	echo "You need rsync for this script to work"
	notify-send "Missing dependency!"
	exit 1
fi

# Sync browsers function, ignore some dirs
_sync_browser() {
	for browser in $BROWSERS; do
		rsync -av --delete \
			--exclude='*/*/storage/default/https*/cache' \
			"$CACHEDIR"/"$browser"/ \
			"$CONFIGDIR"/"$browser".tmpfs/
	done
}

if [ "$1" = "--sync-now" ] && [ -f "$OKFILE" ]; then
	_sync_browser && echo "Manual synced on $(date)" >> "$OKFILE" || exit 1
	echo "Browser sync completed"
	exit 0
fi

# Move config dir to a permanent location
for browser in $BROWSERS; do
		if [ -d "$CONFIGDIR/$browser" ] && [ ! -L "$CONFIGDIR/$browser" ]; then
				mv "$CONFIGDIR/$browser" "$CONFIGDIR/${browser}.tmpfs" || exit 1
				echo "Moved $browser to ${browser}.tmpfs"
		fi
done

# Brave uses its config dir to store cache (Blatant violation of the xdg specs)
# Zen does not even have a config dir and dumpts everything in $HOME lol
mkdir -p "$CACHEDIR" || exit 1
for browser in $BROWSERS; do
		if [ ! -d "$CACHEDIR/$browser" ]; then
				cp -nr "$CONFIGDIR/${browser}.tmpfs" "$CACHEDIR/$browser" \
					&& [ ! -e "$CONFIGDIR/$browser" ] \
					&& ln -s "$CACHEDIR/$browser" "$CONFIGDIR" 2>/dev/null
		fi
done

# INDICATE EVERYTHING IS READY
if [ ! -f "$OKFILE" ]; then
	printf '%s\n' "Syncing record for this session:" >> "$OKFILE" || exit 1
fi

# SYNC EVERY TWO HOURS
while true; do
	echo "tmpfsOK"
	sleep 7200
	_sync_browser && echo "Synced on $(date)" >> "$OKFILE" \
		|| notify-send -u critical "Browser sync error!"
done
