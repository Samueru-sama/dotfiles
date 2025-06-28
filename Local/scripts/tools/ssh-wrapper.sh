#!/bin/sh
# This script must be symlinked in PATH as ssh for it to work
# You also need add UserKnownHostsFile in your ssh config to point to the
# new path where the ssh config is located, for example:
# UserKnownHostsFile ~/Local/config/ssh/known_hosts

CURRENTDIR="$(cd "${0%/*}" && echo "$PWD")"
CONFIGDIR="${XDG_CONFIG_HOME:-$HOME/.config}"

PATH="$(echo "$PATH" | sed "s|$CURRENTDIR:||g; s|:$CURRENTDIR||g")"
export PATH

if [ -f "$CONFIGDIR"/ssh/config ]; then
	set -- "-F" "$CONFIGDIR/ssh/config" "$@"
fi

exec ssh "$@"

