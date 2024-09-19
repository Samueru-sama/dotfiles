#!/usr/bin/env -S awk -f

# caches gpu info for fastfetch

BEGIN {
	if (system("command -v fastfetch 1>/dev/null") != 0) {
		print "You need fastfetch for this script to work"
		exit 1
	}
	CACHEDIR = ENVIRON["XDG_CACHE_HOME"]
	if (CACHEDIR == "") { CACHEDIR = ENVIRON["HOME"] "/.cache" }
	gpu = "fastfetch -s gpu --gpu-detection-method vulkan --pipe -l none \
		2>/dev/null"
	vulkan = "fastfetch -s vulkan --pipe -l none 2>/dev/null"
	while (1) {
		while ((gpu | getline gpu_info) > 0) {
			gsub("GPU ", "", gpu_info)
			gsub("RADV ", "", gpu_info)
			gsub("\[Discrete\]", "", gpu_info)
			printf("%s\n", gpu_info) > CACHEDIR "/gpuinfo"
		}
		while ((vulkan | getline vulkan_info) > 0) {
			gsub("Vulkan ", "", vulkan_info)
			printf("%s\n", vulkan_info) > CACHEDIR "/vulkaninfo"
		}
		close(gpu)
		close(CACHEDIR "/gpuinfo")
		close(vulkan)
		close(CACHEDIR "/vulkaninfo")
		system("sleep 2000")
	}
}

