#!/usr/bin/env -S awk -f

# USED BY POLYBAR TO PRINT THE CURRENT VOLUME IN DECIBELS

BEGIN {
	if (system("command -v pactl 1>/dev/null") != 0) {
		print "You need pactl for this script to work"
		exit 1
	}
	count = 0
	while (1) {
		if (count > 20) {
			cmd = "sleep 0.75 && pactl list sinks"
			# system("echo slow-loop")
		} else {
			cmd = "sleep 0.1 && pactl list sinks"
			# system("echo fast-loop")
		}
		while ((cmd | getline) > 0) {
			if ($2 == "yes") {
			close(cmd)
				output = "Muted\n"
				break
			}
			if ($1 == "Volume:") {
			close(cmd)
			output = sprintf("%.0f dB\n", $7)
				break
			}
		}
		if (output == "") {
		system("sleep 1 && echo NO")
		close(cmd)
		exit 1
		}
		if (output != prev_output) {
			printf output
			prev_output = output
			count = 0
		} else {
			count++
		}
	}
}
