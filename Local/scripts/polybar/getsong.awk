#!/usr/bin/env -S awk -f

# USED BY POLYBAR TO DISPLAY THE CURRENTLY PLAYING MUSIC

BEGIN {
	if (system("command -v playerctl 1>/dev/null") != 0) {
		print "You need playerctl for this script to work"
		exit 1
	}
	cmd = "sleep 1 && playerctl metadata --format \
	'{{ status }}: {{ duration(position) }}/{{ duration(mpris:length) }} {{ title }}' 2>/dev/null"
	while (1) {
		while ((cmd | getline) > 0) {
			if ($1 ~ /^Paused:|^Stopped:/) {
				output = "Paused"
				break
			}
			if ($1 == "Playing:") {
				output = substr($0, length($1) + 2)
				break
			}
		}
		close(cmd)
		if (output != prev_output) {
			printf "%s\n", output
			prev_output = output
		}
	}
}

