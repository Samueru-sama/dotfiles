#!/bin/sh

# This fixes a weird bug in voidlinux where TTY freezes when logging out
# Also fixes a bug in Artixlinux where loginctl doesn't do anything

i3-msg exit
sleep 1 && clear && loginctl terminate-session ${XDG_SESSION_ID-}