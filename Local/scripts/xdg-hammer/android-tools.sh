#!/bin/sh

DATADIR="${XDG_DATA_HOME:-$HOME/.local/share}"
STATEDIR="${XDG_STATE_HOME:-$HOME/.local/state}"
CONFIGDIR="${XDG_CONFIG_HOME:-$HOME/.config}"
CACHEDIR="${XDG_CACHE_HOME:-$HOME/.cache}"
APPHOME="$XDG_DATA_HOME/android/HOME"
APPEXEC="$HOME/Local/opt/android-tools/android-tools"

# SAFETY CHECKS
if ! echo "$PATH" | grep "$BINDIR" >/dev/null 2>&1; then 
	echo 'You have to export PATH="$HOME/.local/bin:$PATH" for this script to work'
	exit 1 
elif ! command -v "$APPEXEC" >/dev/null 2>&1; then 
	echo 'APP is not installed or $APPEXEC has the wrong path set' 
	exit 1 
elif [ -z "$APPHOME" ] || [ -z "$APPEXEC" ] || [ -z "$DATADIR" ] \
	|| [ -z "$STATEDIR" ] || [ -z "$CONFIGDIR" ] || [ -z "$CACHEDIR" ]; then
	echo "You broke the script badly, like what were you thinking?"
	exit 1
fi

# MAKE FAKEHOME AND LINKS
mkdir -p "$APPHOME/.local" "$DATADIR/pki" "$DATADIR/icons" 2>/dev/null
[ ! -e "$APPHOME/.local/share" ] && ln -s "$DATADIR" "$APPHOME/.local/share"
[ ! -e "$APPHOME/.local/state" ] && ln -s "$STATEDIR" "$APPHOME/.local/state"
[ ! -e "$APPHOME/.config" ] && ln -s "$CONFIGDIR" "$APPHOME/.config"
[ ! -e "$APPHOME/.cache" ] && ln -s "$CACHEDIR" "$APPHOME/.cache"
# Some apps have hardcoded ~/.icons path
[ ! -e "$APPHOME/.icons" ] && ln -s "$DATADIR/icons" "$APPHOME/.icons"
# Chromium/electron hardcode ~/.pki
[ ! -e "$APPHOME/.pki" ] && ln -s "$DATADIR/pki" "$APPHOME/.pki"

# Link $HOME files to fakehome
find "$APPHOME" -xtype l -delete
ln -s "$HOME"/* "$APPHOME" >/dev/null 2>&1
# Just in case the app needs a non existent ~/Desktop
[ ! -e "$APPHOME/Desktop" ] && ln -s "$HOME" "$APPHOME/Desktop"
# Uncomment this if you also need to symlink other hidden files to APPHOME.
#ln -s "$HOME"/.* "$APPHOME" >/dev/null 2>&1

# START APP AT APPHOME
HOME="$APPHOME" "$APPEXEC" "$@" || notify-send "App not found"

