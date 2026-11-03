#!/bin/sh
list=$(hyprctl clients -j | python -c "
import sys, json
for c in json.load(sys.stdin):
    if c['workspace']['name'] == 'special:minimized':
        print(c['address'] + '\t' + (c['class'] or '?') + '  -  ' + (c['title'] or ''))
")
if [ -z "$list" ]; then notify-send "Minimizadas" "No hay ventanas minimizadas"; exit 0; fi
sel=$(printf '%s\n' "$list" | cut -f2- | rofi -dmenu -theme $HOME/.config/rofi/glass.rasi -i -p "Restaurar" -format i)
[ -z "$sel" ] && exit 0
addr=$(printf '%s\n' "$list" | sed -n "$((sel+1))p" | cut -f1)
ws=$(hyprctl activeworkspace -j | python -c "import sys,json;print(json.load(sys.stdin)['id'])")
hyprctl dispatch "hl.dsp.window.move({ workspace = $ws, window = \"address:$addr\" })"
hyprctl dispatch "hl.dsp.focus({ window = \"address:$addr\" })"
