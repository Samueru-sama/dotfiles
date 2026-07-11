#!/bin/sh

# Paste image from clipboard as file
type="$(xclip -selection clipboard -t TARGETS -o | grep -m 1 'image')"
extension="$(echo "$type" | awk -F"/" '{print $2}')"

case "$extension" in
	'')
		notify-send "No image copied in clipboard"
		exit 1
		;;
	x-qt-image)
		extension=png
		;;
	jpeg)
		extension=jpg
		;;
esac

if ! FILENAME=$(zenity --entry --width=720 --title "Picture from clipboard" \
  --text "Save .$extension as:" --entry-text="pic-$(date +%Y-%m-%d_%H-%M)"); then
	echo Cancelled
	exit
fi

if [ -z "$1" ]; then
	DEST="$FILENAME.$extension"
else
	DEST="$1/$FILENAME.$extension"
fi

xclip -selection clipboard -t $type -o > "$DEST"

