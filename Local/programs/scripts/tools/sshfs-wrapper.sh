#!/bin/sh

_here=$(cd "${0%/*}" && echo "$PWD")
_configdir=${XDG_CONFIG_HOME:-$HOME/.config}

if [ -f "$_configdir"/ssh/config ]; then
	set -- "-F" "$_configdir"/ssh/config "$@"
fi

exec /usr/bin/sshfs "$@"
