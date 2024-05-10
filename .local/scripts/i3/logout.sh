#!/bin/sh

# This fixes a weird bug in voidlinux where TTY freezes when logging out

i3-msg exit || exit 1

sleep 1 && clear && loginctl terminate-session ${XDG_SESSION_ID-}