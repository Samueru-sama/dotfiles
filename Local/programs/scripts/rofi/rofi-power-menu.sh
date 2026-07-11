#!/bin/sh

# simplified and POSIX version of the original rofi-power-menu
# https://github.com/jluttine/rofi-power-menu

set -e

_option=""
_confirm=""

_print_rofi_option() {
	printf "%s" "<span font_size=\"medium\">$1</span>"
}

printf '\0no-custom\x1ftrue\n'
printf '\0markup-rows\x1ftrue\n'

# check if rofi passed an option
case "$1" in
	--choose) _option=$2;;
	*) _option=$*;;
esac

# make a posix array that contains the message and action separated by :
set -- \
	"Lock Screen:xset dpms force off" \
	"Log Out:loginctl terminate-session $XDG_SESSION_ID" \
	"Reboot:loginctl reboot" \
	"Reboot To BIOS:loginctl reboot --firmware-setup" \
	"Shut Down:loginctl poweroff"

if [ -z "$_option" ]; then
	printf '\0prompt\x1fRofi Power Menu\n'
	for i do
		echo "$(_print_rofi_option "${i%%:*}")"
	done
	exit 0
fi

# now parse the array and perform the respective action
for i do
	_text="${i%%:*}"
	_msg=$(_print_rofi_option "$_text")
	_yes=$(_print_rofi_option "Yes, $_text")
	if [ "$_option" = "$_msg" ]; then
		_confirm=$_yes
		break
	elif [ "$_option" = "$_yes" ]; then
		${i#*:}
		break
	fi
done

if [ -n "$_confirm" ]; then
	printf '\0prompt\x1fAre you sure? (Esc to cancel)\n'
	echo "$_confirm"
fi
