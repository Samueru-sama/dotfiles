#!/usr/bin/env -S awk -f

# USED BY POLYBAR TO PRINT THE GPU STATS

BEGIN {
	getline TOTALPATH < "/sys/class/graphics/fb0/device/mem_info_vram_total"
	TOTAL_GB = TOTALPATH / 1024 / 1024 / 1024
	USED_PATH = "/sys/class/graphics/fb0/device/mem_info_vram_used"
	CORE_PATH = "/sys/class/graphics/fb0/device/gpu_busy_percent"
	while (1) {
		getline USED < USED_PATH
		USED_GB = USED / 1024 / 1024 / 1024
		getline PERCENT < CORE_PATH
		close(USED_PATH)
		close(CORE_PATH)
		printf("%.0f%% %.1f/%.0fGB\n", PERCENT, USED_GB, TOTAL_GB)
		system("sleep 1")
	}
}

