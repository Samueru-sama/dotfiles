#!/bin/sh

PHONEDIR="${XDG_DATA_HOME:-$HOME/.local/share}/Phone" # Replace this with where you want it to be

# CHECK IF PHONE IS ALREADY MOUNTED
mount | grep kdeconnect && { echo "Phone is already mounted"; exit 0; }

# SAFETY CHECKS AND DETERMINE WHICH QDBUS TO USE
if ! command -v kdeconnect-cli 1>/dev/null || ! command -v sshfs 1>/dev/null; then
	echo "Can't find kdeconnect-cli and/or sshfs, is it installed?"
	notify-send "Missing dependency!"
	exit 1
fi

if ! pgrep kdeconnectd >/dev/null 2>&1; then # Tries to start kdeconnectd if it isn't running
	kdeconnectd 2>/dev/null &
	/usr/lib/kdeconnectd 2>/dev/null &
	sleep 1 && pgrep kdeconnectd 1>/dev/null \
	|| { echo "Could not start kdeconnectd, is it installed?"; notify-send "Missing dependency!"; exit 1; }
fi

if command -v qdbus6 >/dev/null 2>&1; then
    QDBUS=qdbus6
elif command -v qdbus-qt5 >/dev/null 2>&1; then
    QDBUS=qdbus-qt5
else
    echo "You need qdbus for this script to work"
	notify-send "Missing dependency!"
	exit 1
fi

_link_phone() { 
	# Get paths
	PHONEPATHS=$("$QDBUS" org.kde.kdeconnect /modules/kdeconnect/devices/"$PHONEID"/sftp getDirectories 2>/dev/null)
	PHONEPATH1=$(echo "$PHONEPATHS" | awk -F ": " 'NR==1 {print $1}')
	PHONEPATH2=$(echo "$PHONEPATHS" | awk -F ": " 'NR==2 {print $1}')
	DIRNAME1=$(echo "$PHONEPATHS" | awk -F ": " 'NR==1 {print $2}')
	DIRNAME2=$(echo "$PHONEPATHS" | awk -F ": " 'NR==2 {print $2}')
	# Make and link dirs
	mkdir -p "$PHONEDIR"
	[ -e "$PHONEPATH1" ] && ln -s "$PHONEPATH1" "$PHONEDIR/$DIRNAME1" 2>/dev/null
	[ -e "$PHONEPATH2" ] && ln -s "$PHONEPATH2" "$PHONEDIR/$DIRNAME2" 2>/dev/null
	ln -s "$PHONEDIR" "$HOME" 2>/dev/null
}

# MOUNT PHONE
while true; do
	if ! mount | grep kdeconnect; then
		find "$PHONEDIR" -xtype l -delete
		PHONEID=$(kdeconnect-cli -a --id-name-only 2>/dev/null | awk '{print $1}')
		if [ -z "$PHONEID" ]; then
			echo "No phone connected"
		else
			"$QDBUS" org.kde.kdeconnect /modules/kdeconnect/devices/"$PHONEID"/sftp mountAndWait
			mount | grep kdeconnect && echo "Phone mounted" && _link_phone
		fi
	fi
	sleep 6
done
