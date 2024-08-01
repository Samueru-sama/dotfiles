#!/bin/sh

# USED BY POLYBAR TO PRINT THE / DISK USAGE

while true; do
	df / -k -h | awk 'FNR == 2 {printf "%sB\n", $3; exit}'
	sleep 7
done

