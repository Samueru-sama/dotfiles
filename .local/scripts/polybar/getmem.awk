#!/usr/bin/env -S awk -f

# USED BY POLYBAR TO PRINT THE RAM AND SWAP USAGE

BEGIN { 
	while (1) {
		while (getline < "/proc/meminfo") {
			if ($1 == "MemTotal:") { TOTAL = $2 }
			if ($1 == "MemFree:") { FREE = $2 }
			if ($1 == "Cached:") { CACHED = $2 }
			if ($1 == "SwapTotal:") { SWAP_TOTAL = $2 }
			if ($1 == "SwapFree:") { SWAP_FREE = $2 }
		}
		close("/proc/meminfo")
		USED = (TOTAL - FREE - CACHED) / 1024 / 1024
		TOTAL_GB = TOTAL / 1024 / 1024
		SWAP = (SWAP_TOTAL - SWAP_FREE) / 1024 / 1024
		if (SWAP > 0.15) {
			printf("%.1f(%.1f)/%.0fGB\n", USED, SWAP, TOTAL_GB)
		} else {
			printf("%.1f/%.0fGB\n", USED, TOTAL_GB)
		}
		system("sleep 1")
	}
}
