#!/bin/sh
pkill -x rofi && exit 0
exec rofi -modi emoji -show emoji -emoji-mode copy -theme "$HOME/.config/rofi/glass.rasi" -theme-str 'listview { columns: 2; lines: 10; }'
