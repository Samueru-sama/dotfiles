#!/usr/bin/env -S awk -f

BEGIN {
	if (system("command -v speedtest-go 1>/dev/null") != 0) {
		print "You need speedtest-go for this script to work"
		exit 1
	}
	CACHEDIR = ENVIRON["XDG_CACHE_HOME"]
	if (CACHEDIR == "") { CACHEDIR = ENVIRON["HOME"] "/.cache" }
	test = "sleep 3 && speedtest-go 2>/dev/null"
	while (1) {
		while ((test | getline) > 0) {
			if ($2 == "Download:") { DOWN = $3 + 0}
			if ($2 == "Upload:") { UP = $3 + 0 }
			if ($2 == "Latency:") {
				sub(/ms$/, "", $3)
				PING = $3 + 0
			}
		}
		close(test)
		printf("↓↑ %.0f/%.0f Mbps - %.0f ms\n",
			DOWN, UP, PING) >> CACHEDIR "/speedinfo"
		
		if (DOWN < 500) {
			system("notify-send -u critical \
			  'Download Speed too low! " DOWN " Mbps'")
		}
		if (UP < 500) {
			system("notify-send -u critical \
			  'Upload Speed too low! " UP " Mbps'")
		}
		if (PING > 10) {
			system("notify-send -u critical \
			  'Ping too high! " PING " ms'")
		}
		system("sleep 14400")
	}
}
