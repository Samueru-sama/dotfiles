#!/usr/bin/env -S awk -f

# USED BY POLYBAR TO PRINT THE RAM AND SWAP USAGE

BEGIN { 
	if (system("command -v free 1>/dev/null") != 0) {
        print "You need free for this script to work"
        exit 1
    }
	while (1) {
		cmd = "free -m"
		while ((cmd | getline) > 0) 
			if ($1 == "Mem:") {
				mem_total = $2
				mem_used = $2 - $4 - $6
			}
			if ($1 == "Swap:") {
				swap = $3
			}
		close(cmd)
		if (swap > 150) {
			output = sprintf("%.1f(%.1f)/%.0fGB\n", mem_used / 1024, swap / 1024, mem_total / 1024)
		} else {
			output = sprintf("%.1f/%.0fGB\n", mem_used / 1024, mem_total / 1024)
		}
		if (output != prev_output) {
			printf output
			prev_output = output
		}
		system("sleep 0.5")
	}
}
