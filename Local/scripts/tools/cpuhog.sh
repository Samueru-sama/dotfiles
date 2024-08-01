#!/bin/sh

# prints the cpu usage of processes
ps -e -o %cpu,comm,cmd --sort=%cpu | cut -c 1-110 | tail -n 50 | awk '{print "\x1b[33m" $1 " %  " "\x1b[36m " substr($0, index($0, $2))}'

