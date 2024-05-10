#!/bin/sh

window_class=$(i3-msg -t get_tree | jq -r ".. | select(.focused? == true) | .window_properties.class")

if [ "$window_class" != "null" ]; then
    i3-msg "move scratchpad"
    dunstify -r 33 -t 1500 "$window_class Moved to Scratchpad"
fi
