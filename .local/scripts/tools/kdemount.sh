#!/bin/sh

PHONEDIR="${XDG_DATA_HOME:-$HOME/.local/share}/Phone" # Replace this with where you want it to be

# CHECK IF PHONE IS ALREADY MOUNTED
mount | grep kdeconnect && { echo "Phone is already mounted"; exit 0; }

if ! command -v kdeconnect-cli >/dev/null 2>&1; then
	echo "Can't find kdeconnect-cli, is it installed?"; exit 1
fi

# CHECK FOR QDBUS
if command -v qdbus6 >/dev/null 2>&1; then
    QDBUS=qdbus6
elif command -v qdbus-qt5 >/dev/null 2>&1; then
    QDBUS=qdbus-qt5
else
    echo "You need qdbus for this script to work"; exit 1
fi

# Mount phone
PHONEID=$(kdeconnect-cli -a --id-name-only 2>/dev/null | awk '{print $1}')
if [ -z "$PHONEID" ]; then
	echo "No phone connected"; exit 1
fi

"$QDBUS" org.kde.kdeconnect /modules/kdeconnect/devices/"$PHONEID"/sftp mountAndWait || { echo "Error mounting"; exit 1; }

# Get paths
PHONEPATHS=$("$QDBUS" org.kde.kdeconnect /modules/kdeconnect/devices/"$PHONEID"/sftp getDirectories 2>/dev/null)
PHONEPATH1=$(echo "$PHONEPATHS" | awk -F ": " 'NR==1 {print $1}')
PHONEPATH2=$(echo "$PHONEPATHS" | awk -F ": " 'NR==2 {print $1}')
DIRNAME1=$(echo "$PHONEPATHS" | awk -F ": " 'NR==1 {print $2}')
DIRNAME2=$(echo "$PHONEPATHS" | awk -F ": " 'NR==2 {print $2}')

# Make and link dirs
mkdir -p "$PHONEDIR"
find "$PHONEDIR" -xtype l -delete # Clears broken links
[ -e "$PHONEPATH1" ] && ln -s "$PHONEPATH1" "$PHONEDIR/$DIRNAME1" 2>/dev/null
[ -e "$PHONEPATH2" ] && ln -s "$PHONEPATH2" "$PHONEDIR/$DIRNAME2" 2>/dev/null
ln -s "$PHONEDIR" "$HOME" 2>/dev/null