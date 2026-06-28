#!/usr/bin/env bash

# MODIFIED VERSION OF THE ORIGINAL rofi-power-menu https://github.com/jluttine/rofi-power-menu

set -e
set -u

all=(lockscreen logout shutdown reboot rebootbios)
show=("${all[@]}")

declare -A texts
texts[lockscreen]="Lock Screen"
texts[logout]="Log Out"
texts[reboot]="Reboot"
texts[rebootbios]="Reboot To BIOS"
texts[shutdown]="Shut Down"

declare -A actions
actions[lockscreen]="xset dpms force off"
actions[logout]="loginctl terminate-session ${XDG_SESSION_ID-}"
actions[reboot]="loginctl reboot"
actions[rebootbios]="loginctl reboot --firmware-setup"
actions[shutdown]="loginctl poweroff"

# Parse command-line options
parsed=$(getopt --options=h --longoptions=,choices:,choose: --name "$0" -- "$@")
if [ $? -ne 0 ]; then
    echo 'Terminating...' >&2
    exit 1
fi
eval set -- "$parsed"
unset parsed
while true; do
    case "$1" in
        "--choices")
            IFS='/' read -ra show <<< "$2"
            shift 2
            ;;
        "--choose")
            selectionID="$2"
            shift 2
            ;;
        "--")
            shift
            break
            ;;
        *)
            echo "Internal error" >&2
            exit 1
            ;;
    esac
done

function write_message {
    text="<span font_size=\"medium\">$1</span>"
    echo -n "$text"
}

declare -A messages
declare -A confirmationMessages
for entry in "${all[@]}"
do
    messages[$entry]=$(write_message "${texts[$entry]^}")
done
for entry in "${all[@]}"
do
    confirmationMessages[$entry]=$(write_message "Yes, ${texts[$entry]}")
done
confirmationMessages[cancel]=$(write_message "No, cancel")

if [ $# -gt 0 ]
then
    selection="${@}"
else
    if [ -n "${selectionID+x}" ]
    then
        selection="${messages[$selectionID]}"
    fi
fi

echo -e "\0no-custom\x1ftrue"
echo -e "\0markup-rows\x1ftrue"

if [ -z "${selection+x}" ]; then
    echo -e "\0prompt\x1fRofi Power Menu"
    for entry in "${show[@]}"
    do
   echo -e "${messages[$entry]}"
 done
else
  for entry in "${show[@]}"
  do
    if [ "$selection" = "${messages[$entry]}" ]; then
       echo -e "\0prompt\x1fAre you sure (Esc to cancel)"
       echo -e "${confirmationMessages[$entry]}"
       exit 0
    fi
    if [ "$selection" = "${confirmationMessages[$entry]}" ]; then
       # Perform the action
       ${actions[$entry]}
    fi
  done
fi

