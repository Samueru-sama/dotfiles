#!/bin/sh

if ! command -v i3-msg 1>/dev/null || ! command -v jq 1>/dev/null; then
	echo "You need i3-msg and jq for this to work"; exit 1
fi

OLDOUT=""
while true; do
	OUT="$(i3-msg -t get_tree \
	| jq -r ".nodes|.[]|.|.nodes|.[]|.nodes|.[]|select(.name==\"__i3_scratch\")|.floating_nodes|.[]|.nodes|.[]|.window_properties.class" \
	| tr '\n' ' ')"
    if [ "$OUT" != "$OLDOUT" ]; then
        echo "$OUT"
        OLDOUT="$OUT"
    fi
    sleep 0.3
done