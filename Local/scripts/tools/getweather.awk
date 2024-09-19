#!/usr/bin/env -S awk -f

BEGIN {
	if (system("command -v wget 1>/dev/null") != 0) {
		print "You need wget for this script to work"
		exit 1
	}
	CACHEDIR = ENVIRON["XDG_CACHE_HOME"]
	if (CACHEDIR == "") { CACHEDIR = ENVIRON["HOME"] "/.cache" }
	weather = "wget -q 'wttr.in/Maracaibo?format=%C %t %w (%l)\n' -O -"
	while (1) {
		while ((weather | getline weather_info) > 0) {
			printf("%s\n", weather_info) >> CACHEDIR "/weatherinfo"
		}
		close(weather)
		system("sleep 1000")
	}
}

