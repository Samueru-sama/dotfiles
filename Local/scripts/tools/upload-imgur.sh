#!/bin/sh

STATEDIR="${XDG_STATE_HOME:-$HOME/.local/state}/getimgur"
TIME="$(date +"%H:%M:%S_%d-%m-%Y")"

if ! command -v curl >/dev/null 2>&1; then
	echo "ERROR: You need curl for this script to work"
	notify-send "Missing dependency!"
	exit 1
elif ! command -v zenity >/dev/null 2>&1; then
	echo "ERROR: You need zenity for this script to work"
	notify-send "Missing dependency!"
	exit 1
elif [ -z "$1" ]; then
	echo "ERROR: No image specified!"
	notify-send "ERROR: No image specified!"
	exit 1
fi

mkdir -p "$STATEDIR" || exit 1
notify-send -t 2000 "Uploading to Imgur" &
image="$1"

# Imgur upload
ID="313baf0c7b4d3ff" # Stolen from flameshot lol
UPLOAD="$(curl -sF "image=@$image" -H "Authorization: Client-ID $ID" \
  https://api.imgur.com/3/upload 2>/dev/null)"

# Extract URL
URL="$(echo "$UPLOAD" | grep -Po '"link":"\K[^"]+' | sed 's/\\//g')"
DELETE="https://imgur.com/delete/$(echo "$UPLOAD" | grep -Po '"deletehash":"\K[^"]+')"

if [ -z "$URL" ]; then
	echo "ERROR: Something went wrong uploading the image"
	notify-send "ERROR: Something went wrong uploading the image"
	exit 1
fi

# log everything
echo "
IMAGE: $URL
Delete: $DELETE
DEBUG: $UPLOAD" > "$STATEDIR/$TIME"

# Copy to clipboard and notify
printf "$URL" | xclip -selection clipboard
zenity --info --title="Screenshot uploaded" --text="Successfully uploaded!

Link: <a href='$URL'>$URL</a>
Delete: <a href='$DELETE'>$DELETE</a>

Link copied to clipboard, logs stored in:
$STATEDIR"
