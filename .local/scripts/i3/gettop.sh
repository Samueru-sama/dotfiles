#!/bin/sh

i3-msg "layout splith" && xfce4-terminal -e htop &

sleep 0.25

xfce4-terminal &

sleep 0.25

i3-msg splitv && xfce4-terminal -e "amdgpu_top --smi" &

sleep 0.1

xfce4-terminal -x zsh -ic 'lf;clear;zsh' &
