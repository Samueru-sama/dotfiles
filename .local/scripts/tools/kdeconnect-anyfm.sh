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

_mount_and_link_phone() {
	if ! mount | grep kdeconnect >/dev/null 2>&1; then
		"$QDBUS" org.kde.kdeconnect /modules/kdeconnect/devices/"$PHONEID"/sftp mountAndWait \
		|| { notify-send -u critical "Kdeconnect failed to mount phone"; exit 1; }
		notify-send "Phone connected and mounted"
	fi
	
	PHONEPATHS=$("$QDBUS" org.kde.kdeconnect /modules/kdeconnect/devices/"$PHONEID"/sftp getDirectories 2>/dev/null)
	if [ -n "$PHONEPATHS" ]; then
		PHONEPATH1=$(echo "$PHONEPATHS" | awk -F ": " 'NR==1 {print $1}')
		PHONEPATH2=$(echo "$PHONEPATHS" | awk -F ": " 'NR==2 {print $1}')
		DIRNAME1=$(echo "$PHONEPATHS" | awk -F ": " 'NR==1 {print $2}')
		DIRNAME2=$(echo "$PHONEPATHS" | awk -F ": " 'NR==2 {print $2}')

		mkdir -p "$PHONEDIR"
		[ -e "$PHONEPATH1" ] && ln -s "$PHONEPATH1" "$PHONEDIR/$DIRNAME1" 2>/dev/null
		[ -e "$PHONEPATH2" ] && ln -s "$PHONEPATH2" "$PHONEDIR/$DIRNAME2" 2>/dev/null
		ln -s "$PHONEDIR" "$HOME" 2>/dev/null
	fi
}

# CHECK AND MOUNT PHONE
while true; do
	if ! mount | grep kdeconnect >/dev/null 2>&1 || [ -z "$(ls "$PHONEDIR" 2>/dev/null)" ]; then
		find "$PHONEDIR" -xtype l -delete
		PHONEID=$(kdeconnect-cli -a --id-name-only 2>/dev/null | awk '{print $1}')
		if [ -n "$PHONEID" ]; then
			_mount_and_link_phone
		else
			echo "Phone not connected"
		fi
	fi
	sleep 6
done
