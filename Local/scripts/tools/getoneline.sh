#!/bin/sh

# used in fastfetch config to merge some options in one line

if ! command -v fastfetch >/dev/null 2>&1; then
    echo "You need fastfetch for this script to work"
    exit 1
elif [ -z "$SEPARATOR" ]; then
    SEPARATOR=" - "
fi

for arg in "$@"; do
    result="$(fastfetch -s "$arg" --pipe -l none \
        | awk -v ORS="$SEPARATOR" '{print $0}' \
        | sed "s/$arg //Ig; s/Date & Time //g")"
    output="$output$result"
done

# Remove last $SEPARATOR from output
echo "${output%$SEPARATOR}"
