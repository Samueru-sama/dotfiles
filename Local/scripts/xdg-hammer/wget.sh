#!/bin/sh

/usr/bin/wget --hsts-file="${XDG_CACHE_HOME:-$HOME/.cache}/wget-hsts" "$@"

