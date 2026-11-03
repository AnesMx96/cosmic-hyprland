#!/bin/sh
# Alterna luz nocturna (hyprsunset 4500K)
if pgrep -x hyprsunset >/dev/null; then
    pkill -x hyprsunset; notify-send -a "Luz nocturna" -i weather-clear "Luz nocturna" "Desactivada"
else
    setsid -f hyprsunset -t 4500 >/dev/null 2>&1; notify-send -a "Luz nocturna" -i weather-clear-night "Luz nocturna" "Activada · 4500K"
fi
pkill -RTMIN+9 waybar
