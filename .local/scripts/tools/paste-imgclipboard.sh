#!/bin/bash
# Paste image from clipboard as file

type="$(xclip -selection clipboard -t TARGETS -o | grep image | head -n1)"
extension="$(echo "$type" | awk -F"/" '{print $2}')"

if [ -z "$extension" ] ; then
	notify-send "No image copied in clipboard" && exit
elif [ "$extension" == "jpeg" ] ; then
	extension="jpg"
elif [ "$extension" == "x-qt-image" ] ; then
	extension="png"
fi

if ! FILENAME=$(zenity --entry --width=720 --title "Picture from clipboard" --text "Save .$extension as:" --entry-text="pic-$(date +%Y-%m-%d_%H-%M)")
  then
    # echo Cancelled
    exit
fi

if [ -z "$1" ]
  then
    DEST="$FILENAME.$extension"
  else
    DEST="$1/$FILENAME.$extension"
fi

xclip -selection clipboard -t $type -o > $DEST
