#!/usr/bin/env -S awk -f

BEGIN {
    if (system("command -v zenity 1>/dev/null") != 0) {
		print "You need zenity for this script to work"
		exit 1
    } else {
		WEATHER = "`awk '{print $0}' ${XDG_CACHE_HOME:-$HOME/.cache}/weatherinfo`"
        system("zenity --calendar --text=\"" WEATHER "\"")
    }
}

