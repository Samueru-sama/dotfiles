#!/bin/sh
# This script must be symlinked in PATH as ssh for it to work
# You also need add UserKnownHostsFile in your ssh config to point to the
# new path where the ssh config is located, for example:
# UserKnownHostsFile ~/Local/config/ssh/known_hosts

_here=$(cd "${0%/*}" && echo "$PWD")
_configdir=${XDG_CONFIG_HOME:-$HOME/.config}

PATH=$(echo "$PATH" | sed "s|$_here:||g; s|:$_here||g")
export PATH

if [ -f "$_configdir"/ssh/config ]; then
	set -- "-F" "$_configdir"/ssh/config "$@"
fi

exec ssh "$@"

