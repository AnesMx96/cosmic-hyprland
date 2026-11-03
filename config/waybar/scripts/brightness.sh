#!/bin/sh
THEME="$HOME/.config/rofi/wifi.rasi"
[ -f "$THEME" ] || THEME=""
cur=$(brightnessctl -m | cut -d, -f4)
OPTS=""; [ -n "$THEME" ] && OPTS="-theme $THEME"
i=$(printf '%s\n' "󰃠  100 %" "󰃟  75 %" "󰃟  50 %" "󰃞  25 %" "󰃞  10 %" | rofi -dmenu -i -format i -no-custom -p "Brillo" -mesg "Ahora: $cur" $OPTS -theme-str "inputbar { enabled: false; }")
[ -n "$i" ] || exit 0
v=$(printf '%s\n' 100 75 50 25 10 | sed -n "$((i + 1))p")
brightnessctl set "${v}%" >/dev/null
