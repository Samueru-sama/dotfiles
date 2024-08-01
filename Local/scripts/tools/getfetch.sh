#!/bin/sh

# Used by fastfetch to cache gpu info and by getcalendar script to display weather info

if ! command -v fastfetch 1>/dev/null || ! command -v wget 1>/dev/null; then
	echo "You need fastfetch and wget for this script to work"
	exit 1
fi

CACHEDIR="${XDG_CACHE_HOME:-$HOME/.cache}"
mkdir -p "$CACHEDIR/fastfetch" || exit 1
fastfetch -s gpu --gpu-detection-method vulkan --pipe -l none \
	| sed 's/GPU/FineWine™ Encoders/g; s/RADV //g; s/\[Discrete\]//g' \
	> "$CACHEDIR/fastfetch/gpuinfo"
fastfetch -s vulkan --pipe -l none | sed 's/Vulkan //g' \
	> "$CACHEDIR/fastfetch/vulkaninfo"

sleep 3 # Wait a bit for internet
wget -q --spider "wttr.in/Maracaibo,VE?0TF" || { 
	sleep 10 && wget --spider "wttr.in/Maracaibo,?0TF" \
	|| notify-send -u critical "Cannot connect to weather server" }
 
wget -q "wttr.in/Maracaibo?0TF" -O - | sed -E 's/^.{15}//g; /^$/d;' \
	| awk 'NR<5 && NR>1 {$1=$1; printf "%s ", $0}' > "$CACHEDIR/weatherinfo"
[ -n "$(cat "$CACHEDIR/weatherinfo")" ] && echo "(Maracaibo)" >> "$CACHEDIR/weatherinfo"

# Update weather and vulkan info every 20 min
while true; do
	sleep 1200
	wget -q "wttr.in/Maracaibo?0TF" -O - | sed -E 's/^.{15}//g; /^$/d;' \
		| awk 'NR<5 && NR>1 {$1=$1; printf "%s ", $0}' > "$CACHEDIR/weatherinfo"
	[ -n "$(cat "$CACHEDIR/weatherinfo")" ] && echo "(Maracaibo)" >> "$CACHEDIR/weatherinfo"
	fastfetch -s vulkan --pipe -l none | sed 's/Vulkan //g' > "$CACHEDIR/fastfetch/vulkaninfo"
done

