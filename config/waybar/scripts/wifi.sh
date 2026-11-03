#!/bin/sh
nmcli dev wifi rescan >/dev/null 2>&1
ssid=$(nmcli -t -f SIGNAL,SSID dev wifi list | awk -F: '$2!=""{print $1"%  "$2}' | sort -rn | uniq | rofi -dmenu -theme $HOME/.config/rofi/glass.rasi -p "WiFi" | sed 's/^[0-9]*%  //')
[ -z "$ssid" ] && exit 0
if nmcli -t -f NAME con show | grep -qx "$ssid"; then nmcli con up "$ssid"
else pw=$(rofi -dmenu -theme $HOME/.config/rofi/glass.rasi -password -p "Clave de $ssid") && nmcli dev wifi connect "$ssid" password "$pw"; fi
notify-send "WiFi" "$(nmcli -t -f ACTIVE,SSID dev wifi | grep '^yes' | cut -d: -f2)"
