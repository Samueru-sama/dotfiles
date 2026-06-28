#!/usr/bin/env -S awk -f

# USED BY POLYBAR TO PRINT THE / DISK USAGE

BEGIN {
	if (system("command -v df 1>/dev/null") != 0) {
		print "You need df for this script to work"
		exit 1
	}
	cmd = "df / -k -h"
	while (1) {
		while ((cmd | getline) > 0)  {
			if ($1 ~ "/dev/") { USAGE = $3 }
		}
		printf("%sB\n", USAGE)
		close(cmd)
		system("sleep 7")
	}
}
