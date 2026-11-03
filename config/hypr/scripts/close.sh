#!/bin/sh
if pgrep -x rofi >/dev/null; then pkill -x rofi; else hyprctl dispatch 'hl.dsp.window.close()'; fi
