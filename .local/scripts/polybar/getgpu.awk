#!/usr/bin/env -S awk -f

# USED BY POLYBAR TO PRINT THE GPU STATS

BEGIN { 
	getline TOTALPATH < "/sys/module/amdgpu/drivers/pci:amdgpu/0000:03:00.0/mem_info_vram_total"
	TOTAL_GB = TOTALPATH / 1024 / 1024 / 1024
	USED_PATH = "/sys/module/amdgpu/drivers/pci:amdgpu/0000:03:00.0/mem_info_vram_used"
	CORE_PATH = "/sys/module/amdgpu/drivers/pci:amdgpu/0000:03:00.0/gpu_busy_percent"
	while (1) {
		getline USED < USED_PATH
		getline PERCENT < CORE_PATH
		close(USED_PATH)
		close(CORE_PATH)
		printf("%.0f%% %.1f/%.0fGB\n", PERCENT, USED / 1024 / 1024 / 1024, TOTAL_GB)
		system("sleep 1")
	}
}
