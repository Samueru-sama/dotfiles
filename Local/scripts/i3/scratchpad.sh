#!/bin/sh

window_class=$(xdotool getactivewindow getwindowclassname 2>/dev/null)

if ! [ -z "$window_class" ]; then
    i3-msg "move scratchpad"
    dunstify -r 33 -t 1500 "$window_class Moved to Scratchpad"
fi

