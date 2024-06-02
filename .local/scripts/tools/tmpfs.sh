#!/bin/sh

if ! command -v rsync 1>/dev/null; then
	echo "You need rsync for this script to work"
	notify-send "Missing dependency!"
	exit 1
fi

CURRENTUSER="${USER:-${USERNAME:-${LOGNAME}}}"
TMPDIRCACHE="$HOME/.local/var/tmp"
CONFIGDIR="${XDG_CONFIG_HOME:-$HOME/.config}"
CACHEDIR="${XDG_CACHE_HOME:-$HOME/.cache}"
OKFILE=/tmp/tmpfsOK

# Safety checks
if ! cat /etc/fstab | grep /tmp 1>/dev/null; then
	echo "You need /tmp on tmpfs for this script to work"
	notify-send -u critical "You need /tmp to be on tmpfs for this script to work, bailing out"
	exit 1
fi

mkdir -p "/tmp/$CURRENTUSER" && chmod 700 "/tmp/$CURRENTUSER" && [ ! -L "$TMPDIRCACHE" ] && ln -s "/tmp/$CURRENTUSER" "$TMPDIRCACHE"

_sync_browser() {
	rsync -av --delete \
	--exclude='File System' \
	--exclude='Service Worker/ScriptCache' \
	--exclude='Service Worker/CacheStorage' \
	--exclude='History' \
	"$TMPDIRCACHE/BraveMain/BraveSoftware/Brave-Browser/Default/" \
	"$CONFIGDIR/BraveDIR/Brave-Browser/Default/"
}

if [ "$1" = "--sync-now" ]; then
	ls "$OKFILE" || exit 1
	_sync_browser && echo "Manual synced on $(date)" >> "$OKFILE" || exit 1
	echo "Browser sync completed" && notify-send "Browser sync completed!"
	exit 0	
fi

mkdir -p "$TMPDIRCACHE/Volatile" && ln -s "$TMPDIRCACHE/Volatile" "$HOME/" 2>/dev/null # I USE THIS LOCATION FOR BUILDING PROGRAMS AND OTHER TESTS

# MOVING CACHES
mkdir -p "$TMPDIRCACHE/BraveCache/BraveSoftware" && ln -s "$TMPDIRCACHE/BraveCache/BraveSoftware" "$XDG_CACHE_HOME/" 2>/dev/null # Brave Browser cache dir
sed -i 's/"exit_type":"Crashed"/"exit_type":"Normal"/' "$CONFIGDIR/BraveDIR/Brave-Browser/Default/Preferences" # PREVENTS "Restore session?" dialog
mkdir -p "$TMPDIRCACHE/BraveMain/BraveSoftware" && cp -r "$CONFIGDIR/BraveDIR/Brave-Browser" "$TMPDIRCACHE/BraveMain/BraveSoftware" \
&& ln -s "$TMPDIRCACHE/BraveMain/BraveSoftware" "$CONFIGDIR" 2>/dev/null # Brave uses its config dir to store cache (Blatant violation of the xdg specs).

mkdir -p "$TMPDIRCACHE/librewolf" && ln -s "$TMPDIRCACHE/librewolf" "$CACHEDIR" 2>/dev/null # LibreWolf cache dr
mkdir -p "$TMPDIRCACHE/thumbnails" && ln -s "$TMPDIRCACHE/thumbnails" "$CACHEDIR" 2>/dev/null # Thumbnails cache dir
mkdir -p "$TMPDIRCACHE/deadbeef" && ln -s "$TMPDIRCACHE/deadbeef" "$CACHEDIR" 2>/dev/null # Deadbeef cache
mkdir -p "$TMPDIRCACHE/yay" && ln -s "$TMPDIRCACHE/yay" "$CACHEDIR" 2>/dev/null # Yay cache dir
mkdir -p "$TMPDIRCACHE/paru" && ln -s "$TMPDIRCACHE/paru" "$CACHEDIR" 2>/dev/null # Paru cache dir
mkdir -p "$TMPDIRCACHE/go-build" && ln -s "$TMPDIRCACHE/go-build" "$CACHEDIR" 2>/dev/null # Go cache dir
mkdir -p "$TMPDIRCACHE/electron" && ln -s "$TMPDIRCACHE/electron" "$CACHEDIR" 2>/dev/null # I have no idea how this directory was created
mkdir -p "$TMPDIRCACHE/wine" && ln -s "$TMPDIRCACHE/wine" "$CACHEDIR" 2>/dev/null # Wine cache dir
mkdir -p "$TMPDIRCACHE/debuginfod_client" && ln -s "$TMPDIRCACHE/debuginfod_client" "$CACHEDIR" 2>/dev/null # Wtf is this

# INDICATE EVERYTHING IS READY
[ ! -e "$OKFILE" ] && { echo "Syncing record for this session:\n" >> "$OKFILE" || exit 1; }
echo "tmpfsOK"

# SYNC EVERY TWO HOURS AND IGNORE SOME DIRS
while true; do
	sleep 7200
	_sync_browser
	echo "Synced on $(date)" >> "$OKFILE"
done
