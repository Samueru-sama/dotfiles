#!/bin/sh

# SCRATCHPAD INDICATOR FOR POLYBAR

while true; do
	i3-msg -t get_tree | LC_ALL=C awk 'BEGIN{RS="_"} /"fresh",|"changed",/ {count++} END{print count}'
	sleep 0.7
done
