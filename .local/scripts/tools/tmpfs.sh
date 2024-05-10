#!/bin/sh

CURRENTUSER="${USER:-${USERNAME:-${LOGNAME}}}"
TMPDIRCACHE="$HOME/.local/var/tmp" # /tmp is normally mounted on mem alerady. Make sure it is by checking /etc/fstab
CONFIGDIR="${XDG_CONFIG_HOME:-$HOME/.config}"
CACHEDIR="${XDG_CACHE_HOME:-$HOME/.cache}"

mkdir -p "/tmp/$CURRENTUSER" && chmod 700 "/tmp/$CURRENTUSER"
[ ! -L "$TMPDIRCACHE" ] && ln -s "/tmp/$CURRENTUSER" "$TMPDIRCACHE"

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

# INDICATE EVERYTHING IS READY
touch /tmp/tmpfsOK && echo "tmpfsOK"

# SYNC EVERY HOUR AND IGNORE SOME DIRS
while true; do
    sleep 3600
    rsync -av --exclude='Service Worker/CacheStorage' --exclude='History' --exclude='File System' \
        "$TMPDIRCACHE/BraveMain/BraveSoftware/Brave-Browser/Default/" \
        "$CONFIGDIR/BraveDIR/Brave-Browser/Default/"
done
