#!/bin/sh

# OC REFRESH RATE
xrandr --newmode "1440x900_79.00"  144.25  1440 1536 1688 1936  900 903 909 945 -hsync +vsync
xrandr --addmode DP-1 "1440x900_79.00" 
xrandr --addmode DP-2 "1440x900_79.00" 
xrandr --addmode DP-3 "1440x900_79.00"

# SET DISPLAYS TO CUSTOM REFRESH RATE
xrandr --output DP-1 --mode "1440x900_79.00" --pos 0x0 --rotate normal 
xrandr --output DP-2 --primary --mode "1440x900_79.00" --pos 1440x0 --rotate normal 
xrandr --output DP-3 --mode "1440x900_79.00" --pos 2880x0 --rotate normal
