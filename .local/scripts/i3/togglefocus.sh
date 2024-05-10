#!/bin/sh

FOCUS=$(i3-msg -t get_tree | jq 'recurse(.nodes[]?, .floating_nodes[]?) | select(.type == "con" or .type == "floating_con") | select(.focused == true) | .nodes == []')

if [ "$FOCUS" = "true" ]; then
    i3-msg "focus parent"
else
    if [ "$FOCUS" = "false" ]; then
        i3-msg "focus parent", "focus parent"
    else
        i3-msg "focus child", "focus child", "focus child", "focus child", "focus child", "focus child"
    fi
fi
