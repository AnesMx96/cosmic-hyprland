#!/bin/sh
# Datos para hyprlock. Uso: info.sh <greeting|date|music|status|host>
export LC_ALL=es_ES.UTF-8
case "$1" in
  greeting)
    h=$(date +%H)
    if [ "$h" -lt 6 ]; then g="Buenas noches"; elif [ "$h" -lt 13 ]; then g="Buenos días"; elif [ "$h" -lt 21 ]; then g="Buenas tardes"; else g="Buenas noches"; fi
    echo "$g, <b>$USER</b>" ;;
  date)
    date +"%A, %-d de %B" | tr '[:lower:]' '[:upper:]' ;;
  music)
    st=$(playerctl status 2>/dev/null)
    [ "$st" = Playing ] || [ "$st" = Paused ] || { echo ""; exit; }
    t=$(playerctl metadata title 2>/dev/null | cut -c1-48); a=$(playerctl metadata artist 2>/dev/null | cut -c1-32)
    ic=$([ "$st" = Playing ] && echo "󰎈" || echo "󰏤")
    t=$(printf '%s' "$t" | sed 's/&/\&amp;/g;s/</\&lt;/g'); a=$(printf '%s' "$a" | sed 's/&/\&amp;/g;s/</\&lt;/g')
    echo "<span foreground='##8cc3ff'>$ic</span>   <b>$t</b>${a:+  <span foreground='##9fb0cf'>·  $a</span>}" ;;
  status)
    out=""
    ssid=$(LC_ALL=C nmcli -t -f ACTIVE,SSID dev wifi 2>/dev/null | awk -F: '$1=="yes"{print $2; exit}')
    [ -n "$ssid" ] && out="󰤨  $ssid" || out="󰤭  Sin red"
    for b in /sys/class/power_supply/BAT*; do
      [ -d "$b" ] || continue
      c=$(cat "$b/capacity"); s=$(cat "$b/status")
      if [ "$s" = Charging ]; then i="󰂄"; elif [ "$c" -ge 80 ]; then i="󰁹"; elif [ "$c" -ge 50 ]; then i="󰁾"; elif [ "$c" -ge 20 ]; then i="󰁼"; else i="󰁺"; fi
      out="$out      $i  $c%"; break
    done
    cache="$HOME/.cache/lock-weather"
    if [ ! -s "$cache" ] || [ $(( $(date +%s) - $(stat -c %Y "$cache") )) -gt 1800 ]; then
      ( w=$(curl -s -m 5 'https://wttr.in/?format=%t&lang=es' 2>/dev/null | tr -d '+'); case "$w" in *°C) echo "$w" > "$cache" ;; esac ) >/dev/null 2>&1 &
    fi
    [ -s "$cache" ] && out="$out      󰖐  $(cat "$cache")"
    echo "$out" ;;
  host)
    echo "󰌾   Sesión bloqueada  ·  $(hostname)" ;;
esac
