#!/usr/bin/env -S awk -f

BEGIN {
	if (system("command -v speedtest-go 1>/dev/null") != 0) {
		print "You need speedtest-go for this script to work"
		exit 1
	}
	CACHEDIR = ENVIRON["XDG_CACHE_HOME"]
	if (CACHEDIR == "") { cache_dir = ENVIRON["HOME"] "/.cache" }
	test = "sleep 3 && speedtest-go 2>/dev/null"
	while (1) {
		while ((test | getline) > 0) {
			if ($2 == "Download:") { DOWN = $3 }
			if ($2 == "Upload:") { UP = $3 }
			if ($2 == "Latency:") { PING = $3 }
		}
		close(test)
		printf("↓↑ %.0f/%.0f Mbps - %.0f ms\n",
			DOWN, UP, PING) >> CACHEDIR "/speedinfo"
		system("sleep 14400")
	}
}

