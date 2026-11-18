#!/bin/sh

#displays="$(xrandr | awk '/ connected/{print $1}')"
#for d in $displays; do
#	xrandr --output "$d" --mode 1440x900 --rate 74.98
#done

# DP1=DisplayPort-0
# DP2=DisplayPort-1
# DP3=DisplayPort-2

DP1=DP-1
DP2=DP-2
DP3=DP-3

# OC REFRESH RATE
xrandr --newmode "1440x900_79.00"  144.25  1440 1536 1688 1936  900 903 909 945 -hsync +vsync
xrandr --addmode "$DP1" "1440x900_79.00"
xrandr --addmode "$DP2" "1440x900_79.00"
xrandr --addmode "$DP3" "1440x900_79.00"

# SET DISPLAYS TO CUSTOM REFRESH RATE
xrandr --output "$DP1" --mode "1440x900_79.00" --pos 0x0 --rotate normal
xrandr --output "$DP2" --primary --mode "1440x900_79.00" --pos 1440x0 --rotate normal
xrandr --output "$DP3" --mode "1440x900_79.00" --pos 2880x0 --rotate normal

exit 0
