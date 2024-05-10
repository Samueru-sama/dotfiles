#!/usr/bin/env -S awk -f

# USED BY POLYBAR TO PRINT THE GPU STATS

BEGIN {

	if (system("command -v amdgpu_top 1>/dev/null && command -v gron 1>/dev/null") != 0) {
		print "You need amdgpu_top and gron for this script to work"
		exit 1
	}

	FS = "(=|;)" # IF USING GRON INSTEAD OF GRON.AWK CHANGE FOR "(= |;)" 
	cmd = "sleep 0.5 && amdgpu_top -J -n 1 | gron.awk"

	while (1) {
        while ((cmd | getline) > 0) {
            if ($1 ~ "Total VRAM\".*.value") {
                mem_total = $2
            }
            if ($1 ~ "VRAM Usage.*.value") {
                mem_used = $2
            }
            if ($1 ~ "activity.GFX.value") {
                core = $2
            }
        }

		close(cmd)
		output = sprintf("%s%% %0.1f/%0.0fGB", core, mem_used / 1024, mem_total / 1024)

		if (output != prev_output) {
			printf "%s\n", output
			prev_output = output
		}
    }
}
