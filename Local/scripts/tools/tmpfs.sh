#!/bin/sh

if ! command -v rsync 1>/dev/null; then
	echo "You need rsync for this script to work" 
	notify-send "Missing dependency!" 
	exit 1
fi

CONFIGDIR="${XDG_CONFIG_HOME:-$HOME/.config}"
CACHEDIR="${XDG_CACHE_HOME:-$HOME/.cache}"/BraveSoftware
OKFILE="$CACHEDIR"/tmpfsOK

# Sync browser function, ignore some dirs
_sync_browser() {
	rsync -av --delete --exclude='tor' \
	--exclude='Default/File System' \
	--exclude='Default/Service Worker/ScriptCache' \
	--exclude='Default/Service Worker/CacheStorage' \
	--exclude='Default/Cache/Cache_Data' \
	--exclude='Default/History' \
	--exclude='component_crx_cache' \
	--exclude='GrShaderCache' \
	"$CACHEDIR/Brave-Browser/" \
	"$CONFIGDIR/Brave.tmpfs/Brave-Browser/"
}

# Move config dir to a permanent location
if [ -d "$CONFIGDIR/BraveSoftware" ] && [ ! -L "$CONFIGDIR/BraveSoftware" ]; then
	mv "$CONFIGDIR/BraveSoftware" "$CONFIGDIR/Brave.tmpfs" || exit 1
	echo "Moved BraveSoftware to Brave.tmpfs"
fi

if [ "$1" = "--sync-now" ]; then
	ls "$OKFILE" && _sync_browser \
	&& echo "Manual synced on $(date)" >> "$OKFILE" \
	&& echo "Browser sync completed"
	exit 0
fi

# PREVENTS "Restore session?" dialog
sed -i 's/"exit_type":"Crashed"/"exit_type":"Normal"/' \
	"$CONFIGDIR"/Brave.tmpfs/Brave-Browser/Default/Preferences

# Brave uses its config dir to store cache (Blatant violation of the xdg specs)
mkdir -p "$CACHEDIR" \
	&& cp -r "$CONFIGDIR"/Brave.tmpfs/Brave-Browser "$CACHEDIR" \
	&& ln -s "$CACHEDIR" "$CONFIGDIR" 2>/dev/null

# INDICATE EVERYTHING IS READY
[ ! -e "$OKFILE" ] && { 
	printf '%s\n' "Syncing record for this session:" >> "$OKFILE" || exit 1
}

# SYNC EVERY TWO HOURS
while true; do
	echo "tmpfsOK"
	sleep 7200
	_sync_browser && echo "Synced on $(date)" >> "$OKFILE" \
		|| notify-send -u critical "Browser sync error!"
done
