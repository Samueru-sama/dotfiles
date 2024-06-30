#!/bin/sh

notify-send -t 2000 "Uploading to Imgur" &

# Check if file is specified
file="$1"
if [ -z "${file}" ]; then
    notify-send "Error - no file specified" >&2
    exit 1
fi

# Imgur upload
IMGUR_CLIENT_ID="PUTYOUROWNHERE"
response=$(curl -s -F "image=@${file}" -H "Authorization: Client-ID ${IMGUR_CLIENT_ID}" https://api.imgur.com/3/upload)

# Extract URL
url=$(echo "${response}" | grep -Po '"link":"\K[^"]+' | sed 's/\\//g')

# Copy to clipboard and notify
echo -n "${url}" | xclip -selection clipboard
notify-send -t 2000 "Image URL Copied to Clipboard: ${url}"
