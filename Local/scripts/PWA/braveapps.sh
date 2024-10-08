#!/bin/sh

if ! command -v brave 1>/dev/null || ! command -v xdotool 1>/dev/null; then
	echo "You need Brave Browser and xdotool for this to work"
	notify-send "Missing dependency"
	exit 1
elif [ -z "$@" 2>/dev/null ]; then
	echo "No PWA given, bailing out"
	echo "Options are: discord - telegram - whatsapp - piped"
	exit 1
fi

for arg in "$@"; do
	case "$arg" in
		discord)
			i3-msg '[class="Brave" instance="discord.com__app"] focus' 2>/dev/null \
			|| brave --app=https://discord.com/app &
			;;
			
		whatsapp)
			i3-msg '[class="Brave" instance="web.whatsapp.com"] focus' 2>/dev/null \
			|| brave --app=https://web.whatsapp.com &
			;;

		telegram)
			i3-msg '[class="Brave" instance="web.telegram.org__k"] focus' 2>/dev/null \
			|| brave --app=https://web.telegram.org/k &
			;;

		piped)
			VID=$(echo "$@" | grep -o "http[^ ]*" | awk -F / '{print $NF}')
			brave --app="https://piped.kavin.rocks/$VID" --window-name="Piped"
			exit 0
			;;
	esac
done

if ! xdotool search --name "telegram" || ! xdotool search --name "discord" \
	|| ! xdotool search --name "whatsapp"; then
	notify-send "Opening chat applications"
	COUNT=0
	while [ $COUNT -lt 100 ]; do # THIS IS A HACK BECAUSE OF THIS https://github.com/i3/i3/issues/5916
		i3-msg '[class="Brave" instance="web.telegram.org__k"] focus' >/dev/null 2>&1 \
			&& i3-msg layout tabbed >/dev/null 2>&1 \
			&& break
		COUNT=$((COUNT + 1))
		sleep 0.1
	done
fi
