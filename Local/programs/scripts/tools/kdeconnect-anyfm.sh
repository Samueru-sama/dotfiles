#!/bin/sh

PHONEDIR=${XDG_DATA_HOME:-$HOME/.local/share}/Phone

_error() {
	>&2 echo "$*"
	notify-send "$*" || :
	exit 1
}

_dep_check() {
	for d in kdeconnect-cli sshfs qdbus6; do
		command -v "$d" 1>/dev/null || _error "Missing dependency $d"
	done
}

_is_mounted() {
	mount | grep 'kdeconnect.*sshfs'
}

_start_daemon() {
	if ! pgrep kdeconnectd >/dev/null 2>&1; then
		kdeconnectd 2>/dev/null &
		/usr/lib/kdeconnectd 2>/dev/null &
		sleep 1
		if ! pgrep kdeconnectd 1>/dev/null; then
			_error "Cannot start kdeconnectd, is it installed?"
		fi
	fi
}

_mount_and_link_phone() {
	if ! _is_mounted; then
		qdbus6 org.kde.kdeconnect /modules/kdeconnect/devices/"$PHONEID"/sftp mountAndWait \
		|| { notify-send -u critical "Kdeconnect failed to mount phone"; exit 1; }
		mount | grep kdeconnect && notify-send "Phone connected and mounted"
	fi

	PHONEPATHS=$(qdbus6 org.kde.kdeconnect /modules/kdeconnect/devices/"$PHONEID"/sftp getDirectories 2>/dev/null)
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


if _is_mounted; then
	echo "Phone is already mounted, nothing to do."
	exit 0
fi

_dep_check
_start_daemon

# CHECK AND MOUNT PHONE
while :; do
	>&2 echo "Checking..."
	if ! _is_mounted || [ -z "$(ls "$PHONEDIR" 2>/dev/null)" ]; then
		find "$PHONEDIR" -xtype l -delete
		PHONEID=$(kdeconnect-cli -a --id-name-only 2>/dev/null | awk '{print $1}')
		if [ -n "$PHONEID" ]; then
			>&2 echo "Mounting $PHONEID..."
			_mount_and_link_phone
		else
			>&2 echo "Phone not connected"
		fi
	fi
	sleep 10
done

