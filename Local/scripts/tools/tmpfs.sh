#!/bin/sh

# this script assumes that Zen browser is wrapped with a fake home
# in $XDG_CONFIG_HOME/zen-browser

CONFIGDIR="${XDG_CONFIG_HOME:-$HOME/.config}"
CACHEDIR="${XDG_CACHE_HOME:-$HOME/.cache}"
OKFILE="$CACHEDIR"/tmpfsOK

if ! command -v rsync 1>/dev/null; then
	echo "You need rsync for this script to work"
	notify-send "Missing dependency!"
	exit 1
fi

# Sync browsers function, ignore some dirs
_sync_browser() {
	rsync -av --delete --exclude='tor' \
	  --exclude='Brave-Browser/Default/File System' \
	  --exclude='Brave-Browser/Default/Service Worker/ScriptCache' \
	  --exclude='Brave-Browser/Default/Service Worker/CacheStorage' \
	  --exclude='Brave-Browser/Default/Cache/Cache_Data' \
	  --exclude='Brave-Browser/Default/History' \
	  --exclude='Brave-Browser/component_crx_cache' \
	  --exclude='Brave-Browser/GrShaderCache' \
	  --exclude='Brave-Browser/DeferredBrowserMetrics' \
	  --exclude='Brave-Browser/Greaselion' \
	  --exclude='OnDeviceHeadSuggestModel' \
	  --exclude='aoojcmojmmcbpfgoecoadbdpnagfchel' \
	  --exclude='gccbbckogglekeggclmmekihdgdpdgoe' \
	  "$CACHEDIR/BraveSoftware/" \
	  "$CONFIGDIR/Brave.tmpfs/"

	rsync -av --delete \
	  "$CACHEDIR"/zen-browser/ \
	  "$CONFIGDIR"/zen-browser.tmpfs/
}

# Move config dir to a permanent location
if [ -d "$CONFIGDIR"/BraveSoftware ] && [ ! -L "$CONFIGDIR"/BraveSoftware ]; then
	mv "$CONFIGDIR"/BraveSoftware "$CONFIGDIR"/Brave.tmpfs || exit 1
	echo "Moved BraveSoftware to Brave.tmpfs"
fi

if [ -d "$CONFIGDIR"/zen-browser ] && [ ! -L "$CONFIGDIR"/zen-browser ]; then
	mv "$CONFIGDIR/zen-browser" "$CONFIGDIR/zen-browser.tmpfs" || exit 1
	echo "Moved zen-browser to zen-browser.tmpfs"
fi

if [ "$1" = "--sync-now" ] && [ -f "$OKFILE" ]; then
	_sync_browser && echo "Manual synced on $(date)" >> "$OKFILE" || exit 1
	echo "Browser sync completed"
	exit 0
fi

# PREVENTS "Restore session?" dialog
sed -i 's/"exit_type":"Crashed"/"exit_type":"Normal"/' \
	"$CONFIGDIR"/Brave.tmpfs/Brave-Browser/Default/Preferences

# Brave uses its config dir to store cache (Blatant violation of the xdg specs)
# Zen does not even have a config dir and dumpts everything in $HOME lol
mkdir -p "$CACHEDIR" || exit 1
if [ ! -d "$CACHEDIR"/BraveSoftware ]; then
	cp -r "$CONFIGDIR"/Brave.tmpfs "$CACHEDIR"/BraveSoftware || exit 1
fi
if [ ! -d "$CACHEDIR"/zen-browser ]; then
	cp -r "$CONFIGDIR"/zen-browser.tmpfs "$CACHEDIR"/zen-browser || exit 1
fi

if [ ! -e "$CONFIGDIR"/BraveSoftware ]; then
	ln -s "$CACHEDIR"/BraveSoftware "$CONFIGDIR" 2>/dev/null
fi
if [ ! -e "$CONFIGDIR"/zen-browser ]; then
	ln -s "$CACHEDIR"/zen-browser "$CONFIGDIR" 2>/dev/null
fi

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
