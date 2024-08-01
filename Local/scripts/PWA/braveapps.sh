#!/bin/sh

if ! command -v brave 1>/dev/null || ! command -v xdotool 1>/dev/null; then
	echo "You need Brave Browser and xdotool for this to work"
	notify-send "Missing dependency"
	exit 1
fi

case args in "$@"
	discord)
		i3-msg '[class="Brave" instance="discord.com__app"] focus' 2>/dev/null || brave --app=https://discord.com/app &
		;;
		
	whatsapp)
		i3-msg '[class="Brave" instance="web.whatsapp.com"] focus' 2>/dev/null || brave --app=https://web.whatsapp.com &
		;;

	telegram)
		i3-msg '[class="Brave" instance="web.telegram.org__k"] focus' 2>/dev/null || brave --app=https://web.telegram.org/k &
		;;

	piped)
		VID=$(echo "$@" | awk -F / '{print $NF}')
		brave --app="https://piped.kavin.rocks/$VID" --window-name="Piped" &
		exit 0
		;;
esac

if ! xdotool search --name "telegram" || ! xdotool search --name "discord" || ! xdotool search --name "whatsapp"; then
	notify-send "Opening chat applications"
	COUNT=0
	while [ $COUNT -ne 100 ]; do		# THIS IS A HACK BECAUSE OF THIS https://github.com/i3/i3/issues/5916
		i3-msg '[class="Brave" instance="web.telegram.org__k"] focus' && i3-msg layout tabbed && break
		COUNT=$((COUNT + 1))
		sleep 0.2
	done
fi

