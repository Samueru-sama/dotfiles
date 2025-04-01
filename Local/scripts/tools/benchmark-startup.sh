#!/bin/bash

# This script is used to determines the startup time of applications
# It only works if your WM is configured to focus on new windows automatically

# Start the application and time
$1 >/dev/null 2>&1 &
START=$(date +%s%N)

# Loop until the window is found by xdotool
while true; do
    window_class="$(xdotool getactivewindow getwindowname 2>/dev/null)"
    if echo "$window_class" | grep -qi "$2"; then
        break
    fi
    sleep 0.001
done

# END TIME
END=$(date +%s%N)

TIME=$((($END - $START) / 1000000))

echo "Time taken: $TIME miliseconds"

