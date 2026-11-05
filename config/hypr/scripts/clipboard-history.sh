#!/usr/bin/env bash
selection=$(cliphist list | rofi -dmenu -p "Portapapeles" -theme "$HOME/.config/rofi/glass.rasi") || exit 0
[ -n "$selection" ] || exit 0
printf '%s\n' "$selection" | cliphist decode | wl-copy
