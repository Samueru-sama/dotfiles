#!/bin/sh

DATADIR="${XDG_DATA_HOME:-$HOME/.local/share}"
STATEDIR="${XDG_STATE_HOME:-$HOME/.local/state}"
CONFIGDIR="${XDG_CONFIG_HOME:-$HOME/.config}"
CACHEDIR="${XDG_CACHE_HOME:-$HOME/.cache}"

APPHOME="$STATEDIR/Brave/HOME"
APPEXEC="$HOME/.local/opt/brave-appimage/brave-appimage" # Replace this to the right path to app if it is not in /usr/bin/brave
APPDESKTOP="/usr/share/applications/brave.desktop" # Might be in a different location in some distros

# SAFETY CHECKS
if ! echo "$PATH" | grep .local/bin >/dev/null 2>&1; then echo 'You have to export PATH="$HOME/.local/bin:$PATH" for this script to work'; exit 1; fi
if ! command -v "$APPEXEC" >/dev/null 2>&1; then echo 'APP is not installed or $APPEXEC has the wrong path set'; exit 1; fi

if [ -z "$APPHOME" ] || [ -z "$APPEXEC" ] || [ -z "$APPDESKTOP" ] || [ -z "$DATADIR" ] || [ -z "$STATEDIR" ] || [ -z "$CONFIGDIR" ] || [ -z "$CACHEDIR" ]; then
	echo "You broke the script badly, like what were you thinking?"; exit 1
fi

# PATCH APP DESKTOP FILE
if ! ls "$DATADIR"/applications/*brave-appimage.desktop >/dev/null 2>&1; then
	cp "$APPDESKTOP" "$DATADIR"/applications/brave-appimage.desktop || { echo "Couldn't copy $APPDESKTOP" & exit 1; }
fi

if ! grep "Exec=brave %U" "$DATADIR"/applications/*brave-appimage.desktop >/dev/null 2>&1; then
	sed -i "s#Exec=[^ ]*#Exec=brave#g" "$DATADIR"/applications/*brave-appimage.desktop && echo "patched librewolf.desktop"
fi

# MAKE FAKEHOME AND LINKS
mkdir -p "$APPHOME/.local" "$DATADIR/pki" "$DATADIR/icons" 2>/dev/null
[ ! -e "$APPHOME/.local/share" ] && ln -s "$DATADIR" "$APPHOME/.local/share"
[ ! -e "$APPHOME/.local/state" ] && ln -s "$STATEDIR" "$APPHOME/.local/state"
[ ! -e "$APPHOME/.config" ] && ln -s "$CONFIGDIR" "$APPHOME/.config"
[ ! -e "$APPHOME/.cache" ] && ln -s "$CACHEDIR" "$APPHOME/.cache"
[ ! -e "$APPHOME/.icons" ] && ln -s "$DATADIR/icons" "$APPHOME/.icons" # Some apps have hardcoded ~/.icons path
[ ! -e "$APPHOME/.pki" ] && ln -s "$DATADIR/pki" "$APPHOME/.pki" # Chromium/electron hardcode ~/.pki

find "$APPHOME" -xtype l -delete # Clears broken links
ln -s "$HOME"/* "$APPHOME" >/dev/null 2>&1 # Symlinks other files in $HOME to $APPHOME
#ln -s "$HOME"/.* "$APPHOME" >/dev/null 2>&1 # Uncomment this if you also need to symlink other hidden files to APPHOME.
[ ! -e "$APPHOME/Desktop" ] && ln -s "$HOME" "$APPHOME/Desktop" # Just in case the app needs a non existent ~/Desktop

# START APP AT APPHOME
cat "$CACHEDIR"//BraveSoftware/tmpfsOK || { echo "tmpfs is not ready"; notify-send "wait a sec for tmpfs"; sleep 5; } # Check tmpfs is ready
cat "$CACHEDIR"//BraveSoftware/tmpfsOK || { notify-send "tmpfs failure"; echo "Error tmpfs"; exit 1; }
HOME="$APPHOME" "$APPEXEC" --class="Brave" "$@" || notify-send "App not found"
